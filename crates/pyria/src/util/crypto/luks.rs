use std::{fs, path::Path};

use anyhow::Context;
use either::Either;
use libcryptsetup_rs::{
    CryptDevice, CryptInit, CryptParamsLuks2Ref, TokenInput, consts::{
        flags::{CryptActivate, CryptDeactivate},
        vals::{EncryptionFormat, KeyslotInfo},
    }
};
use zeroize::Zeroizing;
use super::key::PyriaKeyMetadata;

const TOKEN_TYPE: &str = "pyria-key";
pub struct Luks2DeviceWrapper {
    cd: CryptDevice,
    active_name: Option<String>,
}

impl Luks2DeviceWrapper {
    /// Format a new LUKS2 device and add the provided key as keyslot 0.
    /// `key` is used as both the volume key and the first keyslot passphrase.
    /// For detached-header devices use `Either::Right((header_path, data_path))`.
    pub fn create(
        location: Either<&Path, (&Path, &Path)>,
        key: Zeroizing<Vec<u8>>,
    ) -> anyhow::Result<Self> {
        if let Either::Right((header, _)) = &location {
          let header = fs::File::create(header).context("create header file")?;
          header.set_len(1024 * 1024 * 2).context("extend header file")?;
        }
        let mut cd = CryptInit::init_with_data_device(location)?;
        

        cd.context_handle()
            .format::<()>(
                EncryptionFormat::Luks2,
                ("aes", "xts-plain64"),
                None,
                Either::Left(&*key),
                None,
            )
            .context("format LUKS2")?;

        // after format, the only credential that can authorize keyslot operations
        // is the raw volume key — add it as keyslot 0
        cd.keyslot_handle()
            .add_by_passphrase(None, &*key, &*key)
            .context("add initial keyslot")?;

        Ok(Self { cd, active_name: None })
    }

    /// Load an existing LUKS2 device header without activating it.
    pub fn open(location: Either<&Path, (&Path, &Path)>) -> anyhow::Result<Self> {
        let mut cd = CryptInit::init_with_data_device(location)?;
        cd.context_handle()
            .load::<CryptParamsLuks2Ref>(Some(EncryptionFormat::Luks2), None)
            .context("load LUKS2 header")?;
        Ok(Self { cd, active_name: None })
    }

    /// Activate the device mapper under `name` using `key` as the keyslot passphrase.
    pub fn unlock(&mut self, key: Zeroizing<Vec<u8>>, name: String) -> anyhow::Result<()> {
        self.cd
            .activate_handle()
            .activate_by_passphrase(Some(&name), None, &*key, CryptActivate::empty())
            .context("activate by passphrase")?;
        self.active_name = Some(name);
        Ok(())
    }

    /// Suspend (lock) the active mapper, leaving the device encrypted in memory.
    pub fn lock(&mut self) -> anyhow::Result<()> {
        let name = self
            .active_name
            .as_deref()
            .ok_or_else(|| anyhow::anyhow!("device is not unlocked"))?;
        self.cd.context_handle().suspend(name).context("suspend device")?;
        Ok(())
    }

    /// Deactivate (close) the active mapper.
    pub fn close(&mut self) -> anyhow::Result<()> {
        let name = self
            .active_name
            .take()
            .ok_or_else(|| anyhow::anyhow!("device is not unlocked"))?;
        self.cd
            .activate_handle()
            .deactivate(&name, CryptDeactivate::empty())
            .context("deactivate device")?;
        Ok(())
    }

    /// Destroy all active keyslots and their associated pyria tokens.
    /// This is permanent and irrecoverable.
    pub fn nuke(&mut self) -> anyhow::Result<()> {
        // remove pyria tokens first so the header stays consistent
        for token_idx in 0u32..32 {
            if is_pyria_token(&mut self.cd, token_idx) {
                let _ = self
                    .cd
                    .token_handle()
                    .json_set(TokenInput::RemoveToken(token_idx));
            }
        }

        for slot in 0u32..32 {
            match self.cd.keyslot_handle().status(slot) {
                Ok(KeyslotInfo::Active | KeyslotInfo::ActiveLast | KeyslotInfo::Unbound) => {
                    self.cd
                        .keyslot_handle()
                        .destroy(slot)
                        .with_context(|| format!("destroy keyslot {slot}"))?;
                }
                _ => {}
            }
        }
        Ok(())
    }

    /// Add a keyslot protected by `new_key`, authorized by `existing_key`, and
    /// record `key_metadata` as a LUKS2 token linked to the new keyslot.
    pub fn add_key(
        &mut self,
        existing_key: Zeroizing<Vec<u8>>,
        new_key: Zeroizing<Vec<u8>>,
        key_metadata: PyriaKeyMetadata,
    ) -> anyhow::Result<()> {
        let slot = self
            .cd
            .keyslot_handle()
            .add_by_passphrase(None, &*existing_key, &*new_key)
            .context("add keyslot")?;

        // serialize the metadata struct, then inject the required LUKS2 token fields
        let mut token_json =
            serde_json::to_value(&key_metadata).context("serialize key metadata")?;
        token_json["type"] = serde_json::Value::String(TOKEN_TYPE.to_string());
        token_json["keyslots"] = serde_json::json!([]);

        let token_idx = self
            .cd
            .token_handle()
            .json_set(TokenInput::AddToken(&token_json))
            .context("write token")?;

        self.cd
            .token_handle()
            .assign_keyslot(token_idx, Some(slot))
            .context("assign token to keyslot")?;

        Ok(())
    }

    /// Return the key metadata for every pyria-managed keyslot in the header.
    pub fn get_keys(&mut self) -> Vec<PyriaKeyMetadata> {
        let mut keys = Vec::new();
        for token_idx in 0u32..32 {
            let Ok(json) = self.cd.token_handle().json_get(token_idx) else { continue };
            if json.get("type").and_then(|t| t.as_str()) != Some(TOKEN_TYPE) {
                continue;
            }
            let Ok(meta) = serde_json::from_value::<PyriaKeyMetadata>(json) else { continue };
            keys.push(meta);
        }
        keys
    }

    /// Verify `key` against the device, remove the associated pyria token, and
    /// destroy the keyslot. Errors if `key` does not match any keyslot.
    pub fn remove_key(&mut self, key: Zeroizing<Vec<u8>>) -> anyhow::Result<()> {
        // verify the key and discover which slot it belongs to
        let slot = self
            .cd
            .activate_handle()
            .activate_by_passphrase(None, None, &*key, CryptActivate::empty())
            .context("key verification failed")?;

        // find and remove any pyria token associated with this slot
        for token_idx in 0u32..32 {
            if !is_pyria_token(&mut self.cd, token_idx) {
                continue;
            }
            let assigned = self
                .cd
                .token_handle()
                .is_assigned(token_idx, slot)
                .unwrap_or(false);
            if assigned {
                self.cd
                    .token_handle()
                    .json_set(TokenInput::RemoveToken(token_idx))
                    .context("remove token")?;
            }
        }

        self.cd
            .keyslot_handle()
            .destroy(slot)
            .context("destroy keyslot")?;

        Ok(())
    }

    /// Deactivate an already-active device mapper by name (no wrapper instance needed).
    pub fn deactivate_by_name(name: &str, header: Option<&Path>) -> anyhow::Result<()> {
        let mut cd = CryptInit::init_by_name_and_header(name, header)
            .context("init by active mapper name")?;
        cd.activate_handle()
            .deactivate(name, CryptDeactivate::empty())
            .context("deactivate")?;
        Ok(())
    }

    /// Suspend an already-active device mapper by name (no wrapper instance needed).
    pub fn suspend_by_name(name: &str) -> anyhow::Result<()> {
        let mut cd = CryptInit::init_by_name_and_header(name, None)
            .context("init by active mapper name")?;
        cd.context_handle().suspend(name).context("suspend")?;
        Ok(())
    }
}

/// Returns true if the token at `token_idx` is a pyria-managed token.
fn is_pyria_token(cd: &mut CryptDevice, token_idx: u32) -> bool {
    cd.token_handle()
        .json_get(token_idx)
        .ok()
        .and_then(|json| {
            json.get("type")
                .and_then(|t| t.as_str())
                .map(|t| t == TOKEN_TYPE)
        })
        .unwrap_or(false)
}
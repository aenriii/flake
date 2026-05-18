use argon2::Params;
use fido2_rs::device::Device;
use zeroize::{Zeroize, ZeroizeOnDrop, Zeroizing};
use serde::{Serialize, Deserialize};

use crate::{crypto::{argon2id, fido2}, sys, ui};

pub struct KeyDerivation {
  pub fido2: KeyDerivationFido2,
  pub tpm2: bool,
  pub passphrase: KeyDerivationPassphrase,
}

pub struct KeyDerivationFido2 {
  pub enabled: bool,
  pub device: Option<Device>,
  pub pin: super::Pin,
  pub id: Option<Zeroizing<Vec<u8>>>,
}

pub struct KeyDerivationPassphrase {
  pub enabled: bool,
  pub passphrase: Option<Zeroizing<Vec<u8>>>,
  pub argon_params: Option<Params>,
  pub salt: Option<Zeroizing<[u8; 32]>>
}

impl KeyDerivation {
  pub fn new() -> anyhow::Result<Self> {
    Ok(Self {
      fido2: KeyDerivationFido2 {
        enabled: false,
        device: None,
        pin: Zeroizing::new(None),
        id: None,
      },
      tpm2: false,
      passphrase: KeyDerivationPassphrase {
        enabled: false,
        passphrase: None,
        argon_params: None,
        salt: None,
      },
    })
  }
  pub fn with_passphrase(mut self, passphrase: Option<Zeroizing<Vec<u8>>>, argon_params: Option<Params>, salt: Option<Zeroizing<[u8; 32]>>) -> Self {
    self.passphrase.enabled = true;
    self.passphrase.passphrase = passphrase;
    self.passphrase.argon_params = argon_params;
    self.passphrase.salt = salt;
    self
  }
  pub fn with_fido2(mut self, device: Device, pin: Zeroizing<Option<String>>, id: Option<Zeroizing<Vec<u8>>>) -> Self {
    self.fido2.enabled = true;
    self.fido2.device = Some(device);
    self.fido2.pin = pin;
    self.fido2.id = id;
    self
  }
  pub fn derive_existing(&self) -> anyhow::Result<Zeroizing<[u8; 64]>> {
    if self.passphrase.enabled && self.passphrase.passphrase.is_none() {
      anyhow::bail!("Passphrase is required but not provided");
    }
    if self.passphrase.enabled && self.passphrase.argon_params.is_none() {
      anyhow::bail!("Argon2 parameters are required but not provided");
    }
    if self.fido2.enabled && self.fido2.device.is_none() {
      anyhow::bail!("FIDO2 device is required but not provided");
    }
    if self.fido2.enabled && self.fido2.id.is_none() {
      anyhow::bail!("FIDO2 id is required but not provided");
    }
    let mut salts = Zeroizing::new(Vec::new());
    match (self.passphrase.enabled, self.fido2.enabled, self.tpm2) {
      (false, false, false) => anyhow::bail!("No key derivation enabled"),
      (_, _, true) => {
        ui::warn("TPM2 keys are not implemented fully currently, check back later!");
        anyhow::bail!("TPM2 keys are not supported yet");
      }
      (_, true, _) => {
        let salt = fido2::hmac_with_id(
          &self.fido2.device.as_ref().unwrap(),
          &self.fido2.id.as_ref().unwrap(),
          self.fido2.pin.clone(),
          fido2::HMAC_SALT_INPUT,
        )?;
        salts.push(*salt)
      }
      (true, false, _) => {
        if self.passphrase.salt.is_none() {
          anyhow::bail!("Passphrase salt is required but not provided");
        }
        salts.push(*(self.passphrase.salt.as_ref().unwrap().clone()));
      }
      _ => {}
    };
    self.derive_stage2(salts)
  }

  pub fn derive_new(&mut self) -> anyhow::Result<(Zeroizing<[u8; 64]>, PyriaKeyMetadata)> {
    if self.passphrase.enabled && self.passphrase.passphrase.is_none() {
      anyhow::bail!("Passphrase is required but not provided");
    }
    if self.passphrase.enabled && self.passphrase.argon_params.is_none() {
      ui::working("finding the best argon2 params for your system, this may take a while...");
      // note: im not sure if it's just a me issue, but 1/3 memory + 4 parallel + 1 iteration takes almost 3 minutes
      // so lets keep this down for now...
      self.passphrase.argon_params = Some(argon2id::find_target_params(sys::total_ram_kb()? as u32 / 6 , 45)?);
    }
    if self.fido2.enabled && self.fido2.device.is_none() {
      anyhow::bail!("FIDO2 device is required but not provided");
    }

    let mut salts = Zeroizing::new(Vec::new());
    match (self.passphrase.enabled, self.fido2.enabled, self.tpm2) {
      (false, false, false) => anyhow::bail!("No key derivation enabled"),
      (_, _, true) => anyhow::bail!("TPM2 keys are not implemented fully currently, check back later!"),
      (_, true, _) => {
        let credential = fido2::enroll(&self.fido2.device.as_ref().unwrap(), self.fido2.pin.clone())?;
        self.fido2.id = Some(Zeroizing::new(credential));
        let salt = fido2::hmac_with_id(
          &self.fido2.device.as_ref().unwrap(),
          &self.fido2.id.as_ref().unwrap(),
          self.fido2.pin.clone(),
          fido2::HMAC_SALT_INPUT,
        )?;
        salts.push(*salt);
      },
      (true, false, _) => {
        let salt = super::secure_random::<32>();
        self.passphrase.salt = Some(salt.clone());
        salts.push(*salt);
      },
      _ => {}
    };
    let key = self.derive_stage2(salts)?;
    let key_type = match (self.passphrase.enabled, self.fido2.enabled, self.tpm2) {
      (true, true, _) => PyriaKeyType::Hybrid { fido2: true, tpm: false },
      (true, _, _) => PyriaKeyType::Simple,
      _ => PyriaKeyType::HwOnly { fido2: self.fido2.enabled, tpm: false },
    };
    Ok((key, PyriaKeyMetadata {
      key_type,
      params: self.passphrase.argon_params.as_ref().map(|it| it.clone().try_into()).transpose()?,
      salt: self.passphrase.salt.as_ref().clone().map(|it| it.to_vec()),
      fido2_credential: self.fido2.id.as_ref().clone().map(|id| id.to_vec()),
    }))
  }

  fn derive_stage2(&self, salts: Zeroizing<Vec<[u8; 32]>>) -> anyhow::Result<Zeroizing<[u8; 64]>> {
    let combined_salt = super::hkdf_merge(salts)?;

    let intermediate = match (self.passphrase.enabled, self.fido2.enabled, self.tpm2) {
      (_, _, true) => anyhow::bail!("TPM2 keys are not implemented fully currently, check back later!"),
      (true, true, _) => {
        let kdf_output = super::argon2id(
          self.passphrase.passphrase.as_ref().unwrap().clone(),
          combined_salt.clone(),
          self.passphrase.argon_params.clone(),
        )?;
        let fido2_output = fido2::hmac_with_id(
          &self.fido2.device.as_ref().unwrap(),
          self.fido2.id.as_ref().unwrap(),
          self.fido2.pin.clone(),
          &kdf_output,
        )?;
        fido2_output
      },
      (true, false, _) => {
        let kdf_output = super::argon2id(
          self.passphrase.passphrase.as_ref().unwrap().clone(),
          combined_salt.clone(),
          self.passphrase.argon_params.clone(),
        )?;
        let mut container = Zeroizing::new([0u8; 32]);
        container.copy_from_slice(&kdf_output);
        container
      },
      (false, true, _) => {
        fido2::hmac_with_id(
          &self.fido2.device.as_ref().unwrap(),
          self.fido2.id.as_ref().unwrap(),
          self.fido2.pin.clone(),
          &*combined_salt,
        )?
      },
      (false, false, _) => {
        unreachable!("checked repeatedly before this call")
      },
    };
    super::hkdf_finalize_key(combined_salt, intermediate)
  }
}
impl TryFrom<PyriaKeyMetadata> for KeyDerivation {
  type Error = anyhow::Error;
  fn try_from(meta: PyriaKeyMetadata) -> anyhow::Result<Self> {
    let mut key_derivation = Self::new()?;
    // unwrap fido2 details
    key_derivation = {
      let fido2_credential = match meta.key_type {
        PyriaKeyType::HwOnly { fido2: true, tpm: _ } | PyriaKeyType::Hybrid { fido2: true, tpm: _ } => {
          Some(meta.fido2_credential.unwrap())
        }
        _ => None,
      };
      if fido2_credential.is_some() {
        key_derivation.with_fido2(fido2::device(None)?.0, Zeroizing::new(None), fido2_credential.map(|it| Zeroizing::new(it)))
      } else {
        key_derivation
      }
    };
    // unwrap passphrase details
    let key_derivation = match meta.key_type {
      PyriaKeyType::HwOnly { .. } => key_derivation,
      _ => {
        key_derivation.with_passphrase(None, meta.params.map(|it| it.try_into()).transpose()?, meta.salt.map(|it| {
          let mut out = Zeroizing::new([0u8; 32]);
          out.copy_from_slice(&it);
          out
        }))
      }
    };
    Ok(key_derivation)
  }
}


#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PyriaKeyMetadata {
  pub key_type: PyriaKeyType,
  /// argon2id parameters used for this key (None = use defaults)
  pub params: Option<ArgonParams>,
  /// random 32-byte salt used for Simple keys (stored in LUKS2 token)
  pub salt: Option<Vec<u8>>,
  /// FIDO2 credential ID for Hybrid / HwOnly keys
  pub fido2_credential: Option<Vec<u8>>,
}

impl PyriaKeyMetadata {
  pub fn uses_fido2(&self) -> bool {
    matches!(self.key_type, PyriaKeyType::Hybrid { fido2: true, .. } | PyriaKeyType::HwOnly { fido2: true, .. })
  }
  pub fn uses_tpm(&self) -> bool {
    matches!(self.key_type, PyriaKeyType::Hybrid { tpm: true, .. } | PyriaKeyType::HwOnly { tpm: true, .. })
  }
  pub fn uses_passphrase(&self) -> bool {
    matches!(self.key_type, PyriaKeyType::Hybrid { .. } | PyriaKeyType::Simple)
  }
}


#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ArgonParams {
  pub memory: u32,
  pub time: u32,
  pub threads: u32,
  pub hash_len: u32,
}

impl TryFrom<ArgonParams> for Params {
  type Error = anyhow::Error;

  fn try_from(params: ArgonParams) -> anyhow::Result<Params> {
    Params::new(
      params.memory,
      params.time,
      params.threads,
      Some(params.hash_len as usize),
    ).map_err(|it| anyhow::anyhow!(it))
  }
}

impl From<Params> for ArgonParams {
  fn from(params: Params) -> Self {
    ArgonParams {
      memory: params.m_cost(),
      time: params.t_cost(),
      threads: params.p_cost(),
      hash_len: params.output_len().unwrap_or(32) as u32,
    }
  }
}

#[derive(Serialize, Deserialize, Clone, Copy, Debug)]
pub enum PyriaKeyType {
  /// Passphrase + FIDO2 and/or TPM
  Hybrid { fido2: bool, tpm: bool },
  /// Hardware only (FIDO2 and/or TPM, no passphrase)
  HwOnly { fido2: bool, tpm: bool },
  /// Passphrase only
  Simple,
}

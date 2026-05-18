use std::path::Path;

use clap::Subcommand;
use either::Either;
use zeroize::Zeroizing;

use crate::{crypto::{fido2, key::{KeyDerivation, PyriaKeyMetadata}}, sys::total_ram_kb, ui};

pub mod close;
pub mod create;
pub mod enroll;
pub mod nuke;
pub mod open;
pub mod unenroll;

#[derive(Subcommand)]
pub enum LuksCommand {
  /// create a new LUKS2 container with an internal filesystem
  Create {
    /// block device to format
    device: String,
    /// mapper name for the device
    name: Option<String>,
    /// path to a detached LUKS2 header file
    #[arg(short = 'H', long)]
    luks_header: Option<String>,
    /// internal filesystem: btrfs (default) or ext4
    #[arg(short = 'f', long, default_value = "btrfs")]
    filesystem: String,
    /// hardware factors for hybrid enrollment (e.g. "fido2")
    #[arg(long)]
    hw: Option<String>,
    /// enroll hardware-only (no passphrase component)
    #[arg(long)]
    hw_only: bool,
  },
  /// enroll a new credential into an existing LUKS2 container
  Enroll {
    /// block device (must already be a LUKS2 container)
    device: String,
    #[arg(short = 'H', long)]
    luks_header: Option<String>,
    /// hardware factors for hybrid enrollment (e.g. "fido2")
    #[arg(long)]
    hw: Option<String>,
    /// enroll hardware-only (no passphrase component)
    #[arg(long)]
    hw_only: bool,
  },
  /// open a LUKS2 container (equivalent to "cryptsetup open")
  Open {
    device: String,
    /// mapper name for the device
    name: Option<String>,
    #[arg(short = 'H', long)]
    luks_header: Option<String>,
  },
  /// close a LUKS2 container (equivalent to "cryptsetup close")
  Close { device: String },
  /// wipe all keyslots from a LUKS2 container — permanent and irrecoverable
  Nuke {
    device: String,
    #[arg(short = 'H', long)]
    luks_header: Option<String>,
    /// required to confirm the operation
    #[arg(long)]
    confirm: bool,
  },
  // /// remove a specific keyslot by number (wip)
  // Unenroll {
  //   device: String,
  //   keyslot: u32,
  //   #[arg(short = 'H', long)]
  //   luks_header: Option<String>,
  // },
  // /// suspend a LUKS2 container in place (wip)
  // Lock { device: String },
  // /// resume a suspended LUKS2 container (wip)
  // Unlock { device: String },
}


/// Derive a device-mapper name from a block device path (e.g. `/dev/sda2` → `sda2`).
pub(super) fn mapper_name(device: &str) -> String {
  std::path::Path::new(device)
    .file_name()
    .and_then(|n| n.to_str())
    .unwrap_or("pyria")
    .to_string()
}

/// Build a `Luks2DeviceWrapper` location from a device path and optional detached header.
pub(super) fn location<'a>(device: &'a str, header: Option<&'a str>) -> Either<&'a Path, (&'a Path, &'a Path)> {
  match header {
    Some(h) => Either::Right((Path::new(h), Path::new(device))),
    None => Either::Left(Path::new(device)),
  }
}

/// Interactively derive the LUKS key for an existing `PyriaKeyMetadata` entry.
///
/// Prompts the user for their credential (passphrase, FIDO2 PIN, etc.) and
/// re-derives the exact same key that was stored at enrollment time.
pub(super) fn derive_key(
  meta: &PyriaKeyMetadata,
) -> anyhow::Result<Zeroizing<[u8; 64]>> {

  let mut key_derivation: KeyDerivation = meta.clone().try_into()?;
  if meta.uses_fido2() {
    let (device, needs_pin) = fido2::device(None)?;
    let pin = if needs_pin { prompt_fido2_pin()? } else { Zeroizing::new(None) };
    
    key_derivation = key_derivation
      .with_fido2(device, pin, meta.fido2_credential.as_ref().map(|it| Zeroizing::new(it.clone())))
  };
  // todo: tpm2
  if meta.uses_passphrase() {
    let passphrase = ui::prompt_passphrase("enter your passphrase")?;
    key_derivation = key_derivation
      .with_passphrase(Some(Zeroizing::new(passphrase.as_bytes().to_vec())), meta.params.as_ref().map(|it| it.clone().try_into()).transpose()?, meta.salt.as_ref().map(|it| {
        let mut out = Zeroizing::new([0u8; 32]);
        out.copy_from_slice(it);
        out
      }))
  };

  key_derivation.derive_existing()
}

/// Interactively enroll a new credential, returning the derived key and its metadata.
///
/// `hybrid` is the optional `--hybrid` string (e.g. `"fido2"`).
/// `hw_only` is whether to skip the passphrase component.
pub(super) fn enroll_credential(
  hybrid: Option<&str>,
  hw_only: bool,
) -> anyhow::Result<(
  Zeroizing<[u8; 64]>,
  crate::crypto::key::PyriaKeyMetadata,
)> {
  let mut key_derivation = KeyDerivation::new()?;
  if let Some(hybrid) = hybrid && hybrid.contains("fido2") {
    let (device, needs_pin) = fido2::device(None)?;
    let pin = if needs_pin { prompt_fido2_pin()? } else { Zeroizing::new(None) };
    
    key_derivation = key_derivation
      .with_fido2(device, pin, None)
  };
  // todo: tpm2
  if !hw_only {
    let passphrase = ui::prompt_passphrase_confirm("enter a new passphrase")?;
    key_derivation = key_derivation
      .with_passphrase(Some(Zeroizing::new(passphrase.as_bytes().to_vec())), None, None)
  };
  
  key_derivation.derive_new()
}

fn prompt_fido2_pin() -> anyhow::Result<crate::crypto::Pin> {
  use crate::ui;
  let pin = ui::prompt_passphrase("enter your FIDO2 PIN")?;
  Ok(Zeroizing::new(Some(pin)))
}

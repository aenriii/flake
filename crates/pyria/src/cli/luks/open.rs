use crate::{ui, unsize_zeroized_slice};
use crate::crypto::luks::Luks2DeviceWrapper;

pub fn run(device: &str, name: Option<&str>, luks_header: Option<&str>) -> anyhow::Result<()> {
  let name = name.map(|it| it.to_string()).unwrap_or(super::mapper_name(device));
  let loc = super::location(device, luks_header);

  ui::working("loading LUKS2 header...");
  let mut wrapper = Luks2DeviceWrapper::open(loc)?;
  ui::ok("header loaded");

  let keys = wrapper.get_keys();
  if keys.is_empty() {
    anyhow::bail!("no pyria-managed keys found in this container");
  }

  // try each enrolled key in order until one unlocks the device
  let mut last_err = anyhow::anyhow!("no matching key found");
  for meta in &keys {
    match super::derive_key(meta) {
      Err(e) => { last_err = e; continue; }
      Ok(key) => {
        ui::working(format!("unlocking /dev/mapper/{name}...").as_str());
        match wrapper.unlock(unsize_zeroized_slice(key), name.clone()) {
          Ok(()) => {
            ui::ok(format!("{name} unlocked at /dev/mapper/{name}").as_str());
            return Ok(());
          }
          Err(e) => { last_err = e; continue; }
        }
      }
    }
  }

  Err(last_err.context("failed to unlock device"))
}
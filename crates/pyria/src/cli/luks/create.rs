use std::process::Stdio;

use zeroize::Zeroizing;

use crate::{crypto, ui};
use crate::crypto::luks::Luks2DeviceWrapper;

pub fn run(device: &str, name: Option<&str>, luks_header: Option<&str>, hw: Option<&str>, hw_only: bool) -> anyhow::Result<()> {
  let name = name.map(|it| it.to_string()).unwrap_or(super::mapper_name(device));  
  let loc = super::location(device, luks_header);

  // generate a random master key to format the device. it's replaced by the
  // real credential-derived key before the function returns
  let master_key: Zeroizing<Vec<u8>> =
    Zeroizing::new(crypto::secure_random::<64>().to_vec());

  ui::working("formatting LUKS2 container...");
  let mut wrapper = Luks2DeviceWrapper::create(loc, master_key.clone())?;
  ui::ok("LUKS2 container formatted");

  // enroll the real credential
  println!();
  let (user_key, metadata) = super::enroll_credential(hw, hw_only)?;

  ui::working("writing key to LUKS2 header...");
  wrapper.add_key(master_key.clone(), Zeroizing::new(user_key.clone().to_vec()), metadata)?;

  // remove the temporary master keyslot now that the real key is enrolled
  wrapper.remove_key(master_key)?;
  ui::ok("temporary key removed");

  // activate the mapper to create the filesystem
  ui::working(format!("activating /dev/mapper/{name}...").as_str());
  wrapper.unlock(Zeroizing::new(user_key.clone().to_vec()), name.to_string())?;

  wrapper.close()?;
  ui::ok(format!("LUKS2 container ready! use `pyria luks open {device}` to mount it").as_str());
  Ok(())
}

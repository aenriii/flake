use crate::ui;
use crate::crypto::luks::Luks2DeviceWrapper;

pub fn run(device: &str, luks_header: Option<&str>, confirm: bool) -> anyhow::Result<()> {
  if !confirm {
    anyhow::bail!(
      "this operation is permanent and irrecoverable.\n\
      re-run with --confirm to proceed."
    );
  }

  let loc = super::location(device, luks_header);

  ui::warn("you are about to wipe ALL keyslots from this LUKS2 container.");
  ui::warn("the data will be permanently inaccessible.");
  println!();
  if !ui::prompt_yes_caps("type YES to confirm the nuke")? {
    println!("aborted.");
    return Ok(());
  }

  ui::working("loading LUKS2 header...");
  let mut wrapper = Luks2DeviceWrapper::open(loc)?;

  ui::working("wiping all keyslots...");
  wrapper.nuke()?;
  ui::ok("all keyslots destroyed.");
  Ok(())
}

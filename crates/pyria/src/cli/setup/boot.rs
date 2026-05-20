use std::path::PathBuf;
use std::process::Command;

use crate::util::ui;

pub fn run(host: &str) -> anyhow::Result<()> {
    ui::working("mounting persistent disk for /mnt...");
    // assumes disks have already been set up and the system is booted from the install media
    // with the LUKS containers already open and mounted at /mnt

    // verify /mnt is set up
    if !std::path::Path::new("/mnt/etc/nixos").exists()
        && !std::path::Path::new("/mnt/nix").exists()
    {
        anyhow::bail!(
            "/mnt does not appear to have the NixOS filesystem mounted. \
             run `pyria setup disks` first and make sure /dev/mapper/nixos is mounted."
        );
    }

    ui::working("generating and enrolling secure boot keys via sbctl...");

    // create sbctl keys
    let status = Command::new("sbctl")
        .args(["create-keys"])
        .status()?;
    if !status.success() {
        anyhow::bail!("sbctl create-keys failed");
    }
    ui::ok("secure boot keys generated");

    // enroll keys (include microsoft keys for compatibility, --yes skips confirmation)
    let status = Command::new("sbctl")
        .args(["enroll-keys", "--microsoft", "--yes-this-might-brick-my-machine"])
        .status()?;
    if !status.success() {
        anyhow::bail!("sbctl enroll-keys failed");
    }
    ui::ok("secure boot keys enrolled in UEFI firmware");

    // copy sbctl db to /mnt so it persists after installation
    let sbctl_db_src = PathBuf::from("/usr/share/secureboot");
    let sbctl_db_dst = PathBuf::from("/mnt/persist/secureboot");
    if sbctl_db_src.exists() {
        copy_dir_all(&sbctl_db_src, &sbctl_db_dst)?;
        ui::ok("secure boot key database copied to /persist/secureboot");
    }

    println!("\nboot setup complete. next step: run `pyria setup hardware --host {host}`");
    Ok(())
}

fn copy_dir_all(src: &PathBuf, dst: &PathBuf) -> anyhow::Result<()> {
    std::fs::create_dir_all(dst)?;
    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let dest = dst.join(entry.file_name());
        if entry.file_type()?.is_dir() {
            copy_dir_all(&entry.path(), &dest)?;
        } else {
            std::fs::copy(entry.path(), &dest)?;
        }
    }
    Ok(())
}

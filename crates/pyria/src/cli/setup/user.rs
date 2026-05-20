use std::path::PathBuf;
use std::process::Command;

use anyhow::Context;

use crate::util::ui;

pub fn run(host: &str, username: &str) -> anyhow::Result<()> {
    let flake_root = find_flake_root()?;
    let users_dir = flake_root.join("users").join(username);

    if !users_dir.exists() {
        anyhow::bail!(
            "users/{username} does not exist. \
             create users/{username}/default.nix and users/{username}/home.nix first."
        );
    }

    let persist_home = PathBuf::from(format!("/mnt/persist/home/{username}"));
    if !persist_home.exists() {
        std::fs::create_dir_all(&persist_home)
            .with_context(|| format!("creating /persist/home/{username}"))?;
        ui::ok(format!("created /persist/home/{username}").as_str());
    }

    // set ownership (uid 1000 is a common first user, but we use the username)
    // in the installer environment, the user may not exist yet, so we use 1000 as fallback
    let chown = Command::new("chown")
        .args(["-R", &format!("{username}:{username}"), &persist_home.to_string_lossy()])
        .status();
    match chown {
        Ok(s) if s.success() => ui::ok(format!("set ownership of /persist/home/{username}").as_str()),
        _ => ui::warn("could not set home directory ownership (user may not exist yet — normal during install)"),
    }

    // optionally set up LUKS-encrypted home
    println!();
    if ui::prompt_yes_lower(&format!("set up LUKS2-encrypted home directory for {username}?"))? {
        setup_encrypted_home(username, &persist_home)?;
    }

    ui::ok(format!("user setup complete for {username}").as_str());
    println!("\nnext step: run `pyria setup install --host {host}`");

    Ok(())
}

fn setup_encrypted_home(username: &str, persist_home: &PathBuf) -> anyhow::Result<()> {
    use crate::util::{disk, luks};

    let home_img = persist_home.parent()
        .unwrap_or(persist_home)
        .join(format!("{username}.img"));

    // create a 10GB sparse image for the home directory
    let status = Command::new("truncate")
        .args(["-s", "10G", &home_img.to_string_lossy()])
        .status()?;
    if !status.success() {
        anyhow::bail!("failed to create home image");
    }
    ui::ok(format!("created 10GB home image at {}", home_img.display()).as_str());

    // set up loop device
    let out = Command::new("losetup")
        .args(["-f", "--show", &home_img.to_string_lossy()])
        .output()?;
    if !out.status.success() {
        anyhow::bail!("losetup failed");
    }
    let loop_dev = String::from_utf8_lossy(&out.stdout).trim().to_string();
    ui::ok(format!("attached loop device {loop_dev}").as_str());

    // format as LUKS2
    let mut cd = luks::open_device(std::path::Path::new(&loop_dev), None)?;
    let (temp_key, temp_slot) = luks::format_with_temp_key(&mut cd)?;
    ui::ok("formatted home as LUKS2");

    // mount and format filesystem
    luks::activate_by_passphrase(&mut cd, &format!("{username}-home"), &temp_key)?;
    disk::format_ext4(&format!("/dev/mapper/{username}-home"), username)?;
    ui::ok("formatted home filesystem as ext4");

    // enroll passphrase for home
    let passphrase = ui::prompt_passphrase_confirm(&format!("home directory passphrase for {username}"))?;
    luks::add_keyslot_by_passphrase(&mut cd, &temp_key, passphrase.as_bytes())?;
    luks::destroy_keyslot(&mut cd, temp_slot)?;
    ui::ok("passphrase enrolled, temporary key removed");

    // clean up
    let _ = Command::new("umount")
        .args([&format!("/dev/mapper/{username}-home")])
        .status();
    let _ = luks::deactivate(&format!("{username}-home"));
    let _ = Command::new("losetup")
        .args(["-d", &loop_dev])
        .status();

    ui::ok(format!("encrypted home image ready at {}", home_img.display()).as_str());
    Ok(())
}

fn find_flake_root() -> anyhow::Result<PathBuf> {
    let mut dir = std::env::current_dir()?;
    loop {
        if dir.join("flake.nix").exists() {
            return Ok(dir);
        }
        if !dir.pop() {
            anyhow::bail!("could not find flake.nix");
        }
    }
}

use std::process::Command;

use crate::util::ui;

pub fn run(host: &str) -> anyhow::Result<()> {
    ui::warn("before continuing, make sure you have configured your user accounts in users/{user}/default.nix and users/{user}/home.nix");

    if !ui::prompt_yes_lower("ready to install? (yes/no)")? {
        println!("aborted. configure your users and run again.");
        return Ok(());
    }

    ui::working(format!("running nixos-install for host {host}...").as_str());

    let flake_ref = format!(
        "{}#{host}",
        std::env::current_dir()?.display()
    );

    let status = Command::new("nixos-install")
        .args(["--flake", &flake_ref, "--root", "/mnt"])
        .status()?;

    if !status.success() {
        anyhow::bail!("nixos-install failed");
    }

    ui::ok(format!("installed {host} successfully!").as_str());
    println!();
    println!("installation complete!");
    println!("you can now reboot into your new system.");
    println!("remember to plug in your FIDO2 key and USB boot drive on every boot.");

    Ok(())
}

use std::path::PathBuf;

use crate::util::ui;

#[derive(serde::Serialize, serde::Deserialize, Default)]
struct HostConfig {
    luks: String,
    lanzaboote: bool,
    kernel_flavor: String,
    kernel_config: String,
    desktops: Vec<String>,
    users: Vec<UserConfig>,
    timezone: String,
    no_compromises: bool,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
struct UserConfig {
    name: String,
    shell: String,
    use_default_dotfiles: bool,
}

pub fn run(host: &str) -> anyhow::Result<()> {
    println!("configuring host: {host}\n");

    let flake_root = find_flake_root()?;
    let host_dir = flake_root.join("hosts").join(host);
    if !host_dir.exists() {
        anyhow::bail!("hosts/{host} does not exist — run `pyria setup init --host {host}` first");
    }

    let mut cfg = HostConfig::default();

    // no-compromises mode
    let no_compromises = ui::prompt_yes_lower(
        "enable no-compromises mode? (forces hardened kernel + fortress config, recommended for high-threat environments)"
    )?;
    cfg.no_compromises = no_compromises;

    // luks config
    let luks_options = &["paranoid (detached header + FIDO2 + passphrase, recommended)", "standard (passphrase only)"];
    let luks_choice = ui::prompt_select("LUKS configuration", luks_options)?;
    cfg.luks = if luks_choice == 0 { "paranoid".into() } else { "standard".into() };

    // lanzaboote
    cfg.lanzaboote = ui::prompt_yes_lower("enable lanzaboote (secure boot signing)?")?;

    // kernel flavor
    if !no_compromises {
        let flavors = &["hardened (recommended, locally compiled)", "common (mainline, faster compile)"];
        let fi = ui::prompt_select("kernel flavor", flavors)?;
        cfg.kernel_flavor = if fi == 0 { "hardened".into() } else { "common".into() };

        let configs = &[
            "default (moderate hardening, minimal performance impact)",
            "hardened (strong hardening, some performance cost)",
            "fortress (maximum hardening, 50-75% performance reduction)",
            "loose (performance-focused, fewer mitigations)",
        ];
        let ci = ui::prompt_select("kernel config", configs)?;
        cfg.kernel_config = match ci {
            0 => "default",
            1 => "hardened",
            2 => "fortress",
            _ => "loose",
        }.into();
    } else {
        cfg.kernel_flavor = "hardened".into();
        cfg.kernel_config = "fortress".into();
        println!("  (kernel: hardened + fortress — no-compromises mode)");
    }

    // desktops
    let desktop_options = &["niri (tiling wayland, recommended)", "plasma6 (KDE Plasma 6)", "none"];
    let desktop_idxs = ui::prompt_multiselect("desktop environments to enable", desktop_options)?;
    cfg.desktops = desktop_idxs.iter().filter_map(|&i| match i {
        0 => Some("niri".to_string()),
        1 => Some("plasma6".to_string()),
        _ => None,
    }).collect();

    // timezone
    cfg.timezone = ui::prompt_input("timezone (e.g. America/New_York, Europe/Madrid)")?.trim().to_string();

    // user accounts
    println!("\nuser accounts — enter usernames one at a time, empty to finish:");
    loop {
        let name = ui::prompt_input("username (or press enter to finish)")?.trim().to_string();
        if name.is_empty() { break; }

        let shells = &["zsh (recommended)", "bash", "fish"];
        let si = ui::prompt_select(&format!("shell for {name}"), shells)?;
        let shell = match si { 0 => "zsh", 1 => "bash", _ => "fish" };

        let dotfiles = ui::prompt_yes_lower(&format!("use default dotfiles for {name}?"))?;
        cfg.users.push(UserConfig {
            name: name.clone(),
            shell: shell.into(),
            use_default_dotfiles: dotfiles,
        });
        ui::ok(format!("added user {name}").as_str());
    }

    if cfg.users.is_empty() {
        anyhow::bail!("at least one user is required");
    }

    write_default_nix(&host_dir, host, &cfg)?;
    ui::ok(format!("wrote hosts/{host}/default.nix").as_str());

    println!("\nconfiguration complete! next step: run `sudo pyria setup hardware --host {host}`");
    Ok(())
}

fn write_default_nix(host_dir: &PathBuf, host: &str, cfg: &HostConfig) -> anyhow::Result<()> {
    let desktops = cfg.desktops.iter()
        .map(|d| format!("\"{d}\""))
        .collect::<Vec<_>>()
        .join(" ");

    let users_nix = cfg.users.iter().map(|u| {
        format!(
            "      {} = {{\n        shell = \"{}\";\n        useDefaultDotfiles = {};\n      }};",
            u.name, u.shell, u.use_default_dotfiles
        )
    }).collect::<Vec<_>>().join("\n");

    let primary_user = &cfg.users[0].name;
    let lanzaboote = cfg.lanzaboote.to_string();

    let nix = format!(
        r#"{{ config, pkgs, ... }}:
{{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/hostprofile.nix
  ];
  hostprofile = {{
    boot.luks = "{luks}";
    boot.lanzaboote = {lanzaboote};
    kernel.flavor = "{kernel_flavor}";
    kernel.config = "{kernel_config}";
    desktops = [ {desktops} ];
    users = {{
{users_nix}
    }};
  }};

  nix.settings.allowed-users = [ "{primary_user}" ];
  nix.gc = {{ automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; }};
  nix.optimise.automatic = true;

  networking.hostName = "{host}";
  time.timeZone = "{tz}";
  system.stateVersion = "25.11";
}}
"#,
        luks = cfg.luks,
        lanzaboote = lanzaboote,
        kernel_flavor = cfg.kernel_flavor,
        kernel_config = cfg.kernel_config,
        tz = cfg.timezone,
    );

    std::fs::write(host_dir.join("default.nix"), nix)?;
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

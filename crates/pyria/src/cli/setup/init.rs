use std::path::{Path, PathBuf};

use anyhow::Context;

use crate::util::ui;

pub fn run(host: &str) -> anyhow::Result<()> {
    let flake_root = find_flake_root()?;
    let template = flake_root.join("hosts/_");
    let dest = flake_root.join("hosts").join(host);

    if dest.exists() {
        anyhow::bail!("hosts/{host} already exists — delete it first if you want to reinitialize");
    }

    // copy template files
    copy_dir(&template, &dest)
        .with_context(|| format!("copying template to hosts/{host}"))?;
    ui::ok(format!("wrote default host files at hosts/{host}").as_str());

    // replace placeholder <hostname> in default.nix
    let default_nix = dest.join("default.nix");
    let content = std::fs::read_to_string(&default_nix)?;
    let content = content.replace("<hostname>", host);
    std::fs::write(&default_nix, content)?;

    // add host to flake.nix
    add_to_flake(&flake_root, host)
        .with_context(|| "updating flake.nix")?;
    ui::ok("added host profile to flake.nix");

    println!("\nAdded default host files at hosts/{host}, and set up a profile in flake.nix.");
    println!("next step: run `sudo pyria setup disks --host {host} -d <data-drive> -b <boot-drive>`");

    Ok(())
}

fn find_flake_root() -> anyhow::Result<PathBuf> {
    // walk up from cwd to find flake.nix
    let mut dir = std::env::current_dir()?;
    loop {
        if dir.join("flake.nix").exists() {
            return Ok(dir);
        }
        if !dir.pop() {
            anyhow::bail!("could not find flake.nix — run pyria from within the flake directory");
        }
    }
}

fn copy_dir(src: &Path, dst: &Path) -> anyhow::Result<()> {
    std::fs::create_dir_all(dst)?;
    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let ty = entry.file_type()?;
        let dest_path = dst.join(entry.file_name());
        if ty.is_dir() {
            copy_dir(&entry.path(), &dest_path)?;
        } else {
            std::fs::copy(entry.path(), &dest_path)?;
        }
    }
    Ok(())
}

fn add_to_flake(flake_root: &Path, host: &str) -> anyhow::Result<()> {
    let flake_path = flake_root.join("flake.nix");
    let content = std::fs::read_to_string(&flake_path)?;

    // insert after the last nixosConfigurations.X = ... block
    // we look for the closing `};` of the last nixosConfiguration and insert before it
    let _insert_marker = "    };";
    let new_entry = format!(
        r#"      nixosConfigurations.{host} = nixpkgs.lib.nixosSystem {{
        inherit system;
        specialArgs = {{ inherit self niri-flake; }};
        modules = [
          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          niri-flake.nixosModules.niri
          ./hosts/{host}/default.nix
        ];
      }};"#
    );

    // find the last occurrence of the nixosConfigurations closing and insert before outputs closing
    let outputs_end = "  };\n}";
    if let Some(pos) = content.rfind(outputs_end) {
        let (before, after) = content.split_at(pos);
        let updated = format!("{before}      {new_entry}\n{after}");
        std::fs::write(&flake_path, updated)?;
    } else {
        anyhow::bail!("could not find insertion point in flake.nix — add the host manually");
    }

    Ok(())
}

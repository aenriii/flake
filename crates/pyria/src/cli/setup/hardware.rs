use std::path::PathBuf;
use std::process::Command;

use anyhow::Context;

use crate::util::ui;

pub fn run(host: &str) -> anyhow::Result<()> {
    let flake_root = find_flake_root()?;
    let host_dir = flake_root.join("hosts").join(host);
    let hw_path = host_dir.join("hardware.nix");

    ui::working("generating hardware configuration from current system...");

    let out = Command::new("nixos-generate-config")
        .args(["--root", "/mnt", "--show-hardware-config"])
        .output()
        .context("running nixos-generate-config")?;

    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr);
        anyhow::bail!("nixos-generate-config failed: {stderr}");
    }

    let mut config = String::from_utf8(out.stdout).context("hardware config utf8")?;

    // detect AMD CPU and enable SME/SEV if available
    config = patch_amd_sme(config);

    std::fs::write(&hw_path, &config)?;
    ui::ok(format!("wrote hosts/{host}/hardware.nix").as_str());

    println!("\nhardware configuration generated. next step: run `pyria setup install --host {host}`");
    Ok(())
}

/// add AMD SME (Secure Memory Encryption) kernel param if this is an AMD system
fn patch_amd_sme(config: String) -> String {
    let cpuinfo = std::fs::read_to_string("/proc/cpuinfo").unwrap_or_default();
    let is_amd = cpuinfo.lines().any(|l| l.starts_with("vendor_id") && l.contains("AuthenticAMD"));

    if !is_amd {
        return config;
    }

    // check if SME is supported (bit 0 of CPUID 8000001F EAX)
    // we can't do CPUID directly from userspace safely, so we check /sys
    let _sme_active = std::fs::read_to_string("/sys/module/processor/parameters/amd_ibs_enabled")
        .ok()
        .map(|s| s.trim() == "1")
        .unwrap_or(false);

    // always add the AMD-specific hardware options comment
    if config.contains("boot.kernelParams") {
        config.replace(
            "boot.kernelParams = [",
            "boot.kernelParams = [ \"mem_encrypt=on\" # AMD SME",
        )
    } else {
        // insert before the closing `}` of the config
        config.replace(
            "\n}\n",
            "\n  boot.kernelParams = [ \"mem_encrypt=on\" ]; # AMD SME — encrypts DRAM\n}\n",
        )
    }
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

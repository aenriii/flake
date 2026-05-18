pub mod disk;
use std::{os::unix::fs::FileTypeExt, process::Command};

use anyhow::{Context, bail};

pub fn run(program: &str, args: &[&str]) -> anyhow::Result<String> {
    let out = Command::new(program)
        .args(args)
        .output()
        .with_context(|| format!("running {program}"))?;
    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr);
        bail!("{program} failed: {stderr}");
    }
    Ok(String::from_utf8_lossy(&out.stdout).to_string())
}

pub fn run_ok(program: &str, args: &[&str]) -> anyhow::Result<()> {
    let _out = run(program, args)?;
    Ok(())
}

pub fn check_root() -> anyhow::Result<()> {
    if nix::unistd::getuid().is_root() {
        Ok(())
    } else {
        bail!("this command must be run as root (try: sudo pyria ...)")
    }
}

pub fn check_disk_writable(disk: &str) -> anyhow::Result<()> {
    // verify the path exists and is a block device
    let meta = std::fs::metadata(disk).with_context(|| format!("{disk} not found"))?;
    if !meta.file_type().is_block_device() {
        bail!("{disk} is not a block device");
    }
    Ok(())
}

pub fn total_ram_kb() -> anyhow::Result<usize> {
    let output = run("free", &["--si", "--bytes"])?;
    let lines = output.lines().collect::<Vec<_>>();
    let ram_kb = lines[1]
        .split_whitespace()
        .nth(1)
        .and_then(|s| s.parse::<usize>().ok())
        .unwrap_or(0);
    Ok(ram_kb / 1024)
}

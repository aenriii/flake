use std::path::Path;

use anyhow::Context;

use crate::sys::{run, run_ok};

/// write a fresh GPT on `disk`, wipe all existing partitions
pub fn write_gpt(disk: &str) -> anyhow::Result<()> {
    run_ok("sgdisk", &["--zap-all", disk])?;
    run_ok("sgdisk", &["--clear", disk])?;
    Ok(())
}

/// create a single partition using sgdisk partition syntax.
/// `type_code` is a GPT type GUID hex code (e.g. "EF00" for ESP, "8300" for Linux).
/// returns the partition path (e.g. "/dev/sda1")
pub fn create_partition(
    disk: &str,
    number: u32,
    start: &str,
    end: &str,
    type_code: &str,
    name: &str,
) -> anyhow::Result<String> {
    let new_arg = format!("{number}:{start}:{end}");
    let type_arg = format!("{number}:{type_code}");
    let name_arg = format!("{number}:{name}");
    run_ok("sgdisk", &["--new", &new_arg, "--typecode", &type_arg, "--change-name", &name_arg, disk])?;
    // settle the partition table
    let _ = run("partprobe", &[disk]);
    let _ = run("udevadm", &["settle"]);
    // build partition path: /dev/sda -> /dev/sda1, /dev/nvme0n1 -> /dev/nvme0n1p1
    let part = if disk.contains("nvme") || disk.contains("mmcblk") {
        format!("{disk}p{number}")
    } else {
        format!("{disk}{number}")
    };
    Ok(part)
}

pub fn format_fat32(partition: &str, label: &str) -> anyhow::Result<()> {
    run_ok("mkfs.fat", &["-F", "32", "-n", label, partition])
}

pub fn format_ext4(partition: &str, label: &str) -> anyhow::Result<()> {
    run_ok("mkfs.ext4", &["-L", label, "-F", partition])
}

pub fn format_btrfs(partition: &str, label: &str) -> anyhow::Result<()> {
    run_ok("mkfs.btrfs", &["-L", label, "-f", partition])
}

pub fn create_btrfs_subvolume(mnt: &str, name: &str) -> anyhow::Result<()> {
    let path = format!("{mnt}/{name}");
    run_ok("btrfs", &["subvolume", "create", &path])
}

/// resolve the by-id symlink for a partition (stable across reboots)
pub fn partition_by_id(partition: &str) -> anyhow::Result<String> {
    let _out = run("blkid", &["-o", "device", "-t", &format!("DEVNAME={partition}")])?;
    // try /dev/disk/by-id/
    let by_id_dir = Path::new("/dev/disk/by-id");
    if by_id_dir.exists() {
        let canonical = std::fs::canonicalize(partition)
            .with_context(|| format!("canonicalize {partition}"))?;
        for entry in std::fs::read_dir(by_id_dir)? {
            let entry = entry?;
            if let Ok(target) = std::fs::canonicalize(entry.path()) {
                if target == canonical {
                    return Ok(entry.path().to_string_lossy().to_string());
                }
            }
        }
    }
    // fallback to the raw device path
    Ok(partition.to_string())
}

pub fn mount(source: &str, target: &str, opts: Option<&str>) -> anyhow::Result<()> {
    std::fs::create_dir_all(target)
        .with_context(|| format!("create mountpoint {target}"))?;
    match opts {
        Some(o) => run_ok("mount", &["-o", o, source, target]),
        None => run_ok("mount", &[source, target]),
    }
}

pub fn mount_luks(dm_name: &str, target: &str) -> anyhow::Result<()> {
    let source = format!("/dev/mapper/{dm_name}");
    mount(&source, target, None)
}

pub fn umount(target: &str) -> anyhow::Result<()> {
    run_ok("umount", &[target])
}

pub fn get_disk_size_gb(disk: &str) -> anyhow::Result<u64> {
    let out = run("blockdev", &["--getsize64", disk])?;
    let bytes: u64 = out.trim().parse().context("parse disk size")?;
    Ok(bytes / 1_000_000_000)
}

pub fn get_partition_count(disk: &str) -> anyhow::Result<u32> {
    let out = run("sgdisk", &["-p", disk])?;
    let count = out.lines()
        .filter(|l| l.trim_start().starts_with(|c: char| c.is_ascii_digit()))
        .count();
    Ok(count as u32)
}
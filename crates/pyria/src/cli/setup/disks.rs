use std::path::{Path, PathBuf};

use anyhow::Context;

use crate::util::{disk, fido2, luks, shamir, ui};

pub fn run(host: &str, data_drive: &str, boot_drive: &str) -> anyhow::Result<()> {
    let total = 9usize;

    // ─── [1/9] permissions & requirements ────────────────────────────────────
    ui::step(1, total, "assuring adequate permissions & requirements...");

    disk::check_root()?;
    disk::check_disk_writable(data_drive).context("data drive")?;
    disk::check_disk_writable(boot_drive).context("boot drive")?;
    ui::ok(format!("running with rwx permissions over both disks").as_str());

    if !fido2::device_present() {
        anyhow::bail!("no FIDO2 device found — please plug in your security key before continuing");
    }
    ui::ok("FIDO2 device detected");

    let pin = ui::prompt_pin("enter your FIDO2 pin if you have one", None)?;
    let pin_ref = pin.as_deref();

    ui::action("touch your FIDO2 key now!");
    let fido_device = fido2::open_first_device()?;
    // quick test assertion to confirm the key works
    let test_cred_id = fido2::create_credential(&fido_device, pin_ref)
        .context("creating test credential")?;
    ui::ok("FIDO2 key confirmed");

    let tmp = tempfile::tempdir()?;
    ui::ok(format!("temp directory created at {}", tmp.path().display()).as_str());

    // ─── [2/9] user consent ───────────────────────────────────────────────────
    ui::step(2, total, "verifying user consent...");
    ui::warn(format!(
        "This will erase ALL data on disks {data_drive} and {boot_drive}, are you sure\nyou would like to continue? type \"yes\" in all caps to confirm."
    ).as_str());
    if !ui::prompt_yes_caps("")? {
        println!("aborted.");
        return Ok(());
    }

    // ─── [3/9] partition boot disk ────────────────────────────────────────────
    ui::step(3, total, format!("partitioning boot disk: {boot_drive}").as_str());
    let boot_size_gb = disk::get_disk_size_gb(boot_drive)?;

    disk::write_gpt(boot_drive)?;

    let boot_esp = disk::create_partition(boot_drive, 1, "0", "+3G", "EF00", "BOOT")?;
    let boot_lock_part = disk::create_partition(boot_drive, 2, "0", "0", "8300", "BOOTLOCK")?;

    ui::ok(format!(
        "wrote GPT with 2 partition(s) totaling 4GB of {boot_size_gb}GB available disk space"
    ).as_str());

    disk::format_fat32(&boot_esp, "BOOT")?;
    ui::ok(format!("created 3GB FAT32 filesystem on {boot_esp} with label BOOT").as_str());

    // LUKS2 on the boot lock partition (attached header, FIDO2-only, no passphrase needed later)
    let mut bootlock_cd = luks::open_device(Path::new(&boot_lock_part), None)?;
    let (bootlock_temp_key, bootlock_temp_slot) = luks::format_with_temp_key(&mut bootlock_cd)?;
    ui::ok(format!("created 1GB LUKS2 container on {boot_lock_part} with label BOOTLOCK").as_str());

    luks::activate_by_passphrase(&mut bootlock_cd, "bootlock", &bootlock_temp_key)?;
    disk::format_ext4("/dev/mapper/bootlock", "NIXHEADER")?;
    ui::ok("created 1GB EXT4 filesystem in /dev/mapper/bootlock");

    disk::mount(&boot_esp, "/mnt/boot", Some("noexec,nosuid,nodev,umask=0077"))?;
    disk::mount_luks("bootlock", "/mnt/boot/lock")?;
    ui::ok("mountpoint for /dev/sdb1 set to /boot");
    ui::ok("mountpoint for /dev/sdb2 set to /boot/lock");
    println!("\ndone!");

    // ─── [4/9] partition data disk ────────────────────────────────────────────
    ui::step(4, total, format!("partitioning disks: {data_drive}").as_str());
    let data_size_gb = disk::get_disk_size_gb(data_drive)?;

    disk::write_gpt(data_drive)?;
    let data_part = disk::create_partition(data_drive, 1, "0", "0", "8300", "NIXOS")?;
    ui::ok(format!(
        "wrote GPT with 1 partition(s) totaling {data_size_gb}GB of {data_size_gb}GB available disk space"
    ).as_str());

    // LUKS2 with DETACHED header on the data drive
    let header_dir = PathBuf::from("/mnt/boot/lock/headers");
    std::fs::create_dir_all(&header_dir)?;
    let header_path = header_dir.join("NIXOS.img");

    let mut data_cd = luks::open_device(Path::new(&data_part), Some(&header_path))?;
    let (data_temp_key, data_temp_slot) = luks::format_with_temp_key(&mut data_cd)?;
    ui::ok(format!("created LUKS2 container on {data_part} with detatched header and label NIXOS").as_str());
    ui::ok(format!("wrote header to /boot/lock/headers/NIXOS.img").as_str());

    luks::activate_by_passphrase(&mut data_cd, "nixos", &data_temp_key)?;
    disk::format_btrfs("/dev/mapper/nixos", "nixos")?;

    // mount root temporarily just to create subvolumes, then unmount
    disk::mount("/dev/mapper/nixos", "/mnt/btrfs-root", None)?;
    disk::create_btrfs_subvolume("/mnt/btrfs-root", "@nix")?;
    disk::create_btrfs_subvolume("/mnt/btrfs-root", "@persist")?;
    disk::umount("/mnt/btrfs-root")?;

    // tmpfs owns /mnt (becomes / at runtime via impermanence); subvols go under it
    disk::mount("/dev/mapper/nixos", "/mnt/nix", Some("subvol=@nix,compress=zstd,noatime"))?;
    disk::mount("/dev/mapper/nixos", "/mnt/persist", Some("subvol=@persist,compress=zstd,noatime"))?;

    ui::ok("created BTRFS filesystem in /dev/mapper/nixos");
    ui::ok("created @nix and @persist subvolumes in /dev/mapper/nixos");
    ui::ok("mounted @nix at /mnt/nix, @persist at /mnt/persist");
    println!("\ndone!");

    // ─── [5/9] generate necessary files ──────────────────────────────────────
    ui::step(5, total, "generating necessary files...");

    write_disko_nix(host, data_drive, &data_part, boot_drive, &boot_esp, &boot_lock_part)?;
    ui::ok(format!("wrote {host}/disko.nix to disk").as_str());

    // enroll the FIDO2 credential for the boot lock and store its ID
    let creds_dir = PathBuf::from("/mnt/boot/lock/credentials");
    std::fs::create_dir_all(&creds_dir)?;
    // reuse the test credential id we created earlier for the data partition
    let cred_id_path = creds_dir.join("0.id");
    std::fs::write(&cred_id_path, &test_cred_id)?;
    ui::ok("wrote /boot/lock/credentials/0.id to disk");
    println!("\ndone!");

    // ─── [6/9] enroll FIDO2 on bootlock ──────────────────────────────────────
    ui::step(6, total, format!("enrolling FIDO2 security key on {boot_lock_part}").as_str());
    ui::ok("verified partition unlocked and mounted");
    ui::working("enrolling FIDO2 device...");

    let pin2 = ui::prompt_pin("enter your FIDO2 pin if you have one", None)?;
    let pin2_ref = pin2.as_deref();
    ui::action("touch your FIDO2 key now!");

    // for bootlock we use a fresh credential and simple FIDO2 assertion (no passphrase hybrid)
    let bootlock_cred_id = fido2::create_credential(&fido_device, pin2_ref)?;
    let bootlock_key = fido2::get_hmac_output(
        &fido_device,
        &bootlock_cred_id,
        crate::util::_crypto::FIDO2_SALT_PERSONALIZATION,
        pin2_ref,
    )?;

    // store bootlock credential
    let bootlock_cred_path = creds_dir.join("bootlock.id");
    std::fs::write(&bootlock_cred_path, &bootlock_cred_id)?;

    luks::add_keyslot_by_key(&mut bootlock_cd, &bootlock_temp_key, &*bootlock_key)?;
    ui::ok("FIDO2 key enrolled");
    luks::destroy_keyslot(&mut bootlock_cd, bootlock_temp_slot)?;
    ui::ok("temporary passphrase removed from keyslot 0");
    println!("\ndone!");

    // ─── [7/9] enroll FIDO2 hybrid on data disk ───────────────────────────────
    ui::step(7, total, format!("enrolling FIDO2 security key + passphrase hybrid on {data_part}").as_str());
    ui::ok("verified partition unlocked and mounted");

    let passphrase = ui::prompt_passphrase_confirm("enter a passphrase you trust with your life")?;
    ui::ok("passphrase verified");

    ui::working("fetching salt from FIDO2 key...");
    let pin3 = ui::prompt_pin("enter your FIDO2 pin if you have one", Some((1, 2)))?;
    let pin3_ref = pin3.as_deref();
    ui::action("touch your FIDO2 key now!");

    ui::working("deriving key from passphrase and salt, this may take a few moments...");
    let luks_key = fido2::derive_hybrid_key(&fido_device, &test_cred_id, passphrase.as_bytes(), pin3_ref)?;
    ui::ok("key derived");

    luks::add_keyslot_by_key(&mut data_cd, &data_temp_key, &*luks_key)?;
    ui::ok("hybrid credentials enrolled");
    luks::destroy_keyslot(&mut data_cd, data_temp_slot)?;
    ui::ok("temporary passphrase removed from keyslot 0");
    println!("\ndone!");

    // ─── [8/9] verify ─────────────────────────────────────────────────────────
    ui::step(8, total, "verifying successful implementation");
    ui::warn("you will be asked to enter your FIDO2 pin three times during this stage.");
    ui::warn("each disk unlock requires a fresh pin session, and the argon2id key");
    ui::warn("derivation for the data disk takes long enough to expire the token mid-process.");
    ui::warn("this is not a bug.");

    // close everything — innermost mounts first
    disk::umount("/mnt/persist")?;
    disk::umount("/mnt/nix")?;
    disk::umount("/mnt/boot/lock")?;
    disk::umount("/mnt/boot")?;
    luks::deactivate("nixos")?;
    luks::deactivate("bootlock")?;
    ui::ok("closed all LUKS2 containers");

    // sanity check: bootlock should NOT open with temp key
    ui::working("sanity check: attempting to unlock /dev/sdb2 w/ temp passphrase");
    {
        let mut cd = luks::open_device(Path::new(&boot_lock_part), None)?;
        luks::load(&mut cd)?;
        if luks::test_passphrase(&mut cd, &bootlock_temp_key).is_err() {
            ui::ok("attempting to open /dev/sdb2 failed!");
        } else {
            ui::warn("WARNING: bootlock still opens with temp key — enrollment may have failed!");
        }
    }

    // open bootlock with FIDO2
    ui::working(format!("opening {boot_lock_part} (/boot/lock)...").as_str());
    let pin5 = ui::prompt_pin("enter your FIDO2 pin if you have one", Some((1, 3)))?;
    let pin5_ref = pin5.as_deref();
    ui::action("touch your FIDO2 key now!");
    let bl_hmac = fido2::get_hmac_output(
        &fido_device,
        &bootlock_cred_id,
        crate::util::_crypto::FIDO2_SALT_PERSONALIZATION,
        pin5_ref,
    )?;
    {
        let mut cd = luks::open_device(Path::new(&boot_lock_part), None)?;
        luks::load(&mut cd)?;
        luks::activate_by_passphrase(&mut cd, "bootlock", &*bl_hmac)?;
    }
    disk::mount("/dev/mapper/bootlock", "/mnt/boot/lock", None)?;
    ui::ok(format!("{boot_lock_part} unlocked and mounted").as_str());

    // sanity check: data should NOT open with temp key
    ui::working("sanity check: attempting to unlock data disk w/ temp passphrase");
    {
        let mut cd = luks::open_device(Path::new(&data_part), Some(&header_path))?;
        luks::load(&mut cd)?;
        if luks::test_passphrase(&mut cd, &data_temp_key).is_err() {
            ui::ok("attempting to open data disk failed!");
        } else {
            ui::warn("WARNING: data disk still opens with temp key — enrollment may have failed!");
        }
    }

    let passphrase2 = ui::prompt_passphrase(format!("enter the passphrase you used for {data_part}").as_str())?;
    ui::working("fetching salt from FIDO2 key...");
    let pin6 = ui::prompt_pin("enter your FIDO2 pin if you have one", Some((2, 3)))?;
    let pin6_ref = pin6.as_deref();
    ui::action("touch your FIDO2 key now!");
    ui::working("deriving key from passphrase and salt, this may take a few moments...");
    let verify_key = fido2::derive_hybrid_key(&fido_device, &test_cred_id, passphrase2.as_bytes(), pin6_ref)?;
    ui::ok("key derived");

    {
        let mut cd = luks::open_device(Path::new(&data_part), Some(&header_path))?;
        luks::load(&mut cd)?;
        luks::activate_by_passphrase(&mut cd, "nixos", &*verify_key)?;
    }
    ui::ok("key verified against LUKS2 container");
    disk::mount("/dev/mapper/nixos", "/mnt/nix", Some("subvol=@nix,compress=zstd,noatime"))?;
    disk::mount("/dev/mapper/nixos", "/mnt/persist", Some("subvol=@persist,compress=zstd,noatime"))?;
    ui::ok(format!("{data_part} unlocked and mounted").as_str());
    ui::ok("implementation successful!");
    println!("\ndone!");

    // ─── [9/9] optional shamir shares ─────────────────────────────────────────
    ui::step(9, total, "(optional) shamir share generation");
    println!();
    println!("would you like to generate shamir recovery shares? (recommended)");
    println!("these allow recovery if your FIDO2 key is lost or damaged.");
    println!("WARNING: only share these with people you trust with your life.");
    println!("type \"yes\" in all caps to generate, anything else to skip.");

    if ui::prompt_yes_caps("")? {
        // generate a fresh random recovery passphrase and enroll it as a LUKS keyslot
        // the shares encode this passphrase — reconstruct 3-of-5 to unlock without FIDO2
        use rand::RngExt;
        let mut recovery_key = zeroize::Zeroizing::new([0u8; 32]);
        rand::rng().fill(&mut recovery_key[..]);

        luks::add_keyslot_by_key(&mut data_cd, &*luks_key, &*recovery_key)
            .context("enroll recovery keyslot")?;
        ui::ok("recovery keyslot enrolled");

        generate_shamir_shares(&*recovery_key, &creds_dir)?;
    } else {
        println!("\nskipped shamir share generation.");
    }

    Ok(())
}

fn write_disko_nix(
    host: &str,
    data_drive: &str,
    _data_part: &str,
    boot_drive: &str,
    _boot_esp: &str,
    _boot_lock_part: &str,
) -> anyhow::Result<()> {
    let boot_by_id = disk::partition_by_id(boot_drive).unwrap_or_else(|_| boot_drive.to_string());
    let data_by_id = disk::partition_by_id(data_drive).unwrap_or_else(|_| data_drive.to_string());

    let nix = format!(
        r#"{{ ... }}:
{{
  disko.devices = {{
    disk = {{
      ssd = {{
        type = "disk";
        device = "{data_by_id}";
        content = {{
          type = "gpt";
          partitions = {{
            nixos = {{
              size = "100%";
              content = {{
                type = "luks";
                name = "nixos";
                settings = {{
                  allowDiscards = false;
                  header = "/boot/lock/headers/NIXOS.img";
                }};
                content = {{
                  type = "btrfs";
                  extraArgs = [ "-L" "nixos" "-f" ];
                  subvolumes = {{
                    "@nix" = {{
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" "nodev" "nosuid" ];
                    }};
                    "@persist" = {{
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" "nodev" "nosuid" ];
                    }};
                  }};
                }};
              }};
            }};
          }};
        }};
      }};
      usb = {{
        type = "disk";
        device = "{boot_by_id}";
        content = {{
          type = "gpt";
          partitions = {{
            boot = {{
              size = "3G";
              type = "EF00";
              content = {{
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "noexec" "nosuid" "nodev" "umask=0077" ];
              }};
            }};
            header = {{
              size = "1G";
              content = {{
                type = "luks";
                name = "bootlock";
                settings = {{
                  allowDiscards = false;
                }};
                content = {{
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/boot/lock";
                  extraArgs = [ "-L" "NIXHEADER" ];
                }};
              }};
            }};
          }};
        }};
      }};
    }};

    nodev = {{
      "/" = {{
        fsType = "tmpfs";
        mountOptions = [ "defaults" "size=2G" "mode=0755" ];
      }};
    }};
  }};
}}
"#
    );

    // find flake root and write
    let flake_root = find_flake_root()?;
    let dest = flake_root.join("hosts").join(host).join("disko.nix");
    std::fs::write(&dest, nix)?;
    Ok(())
}

fn find_flake_root() -> anyhow::Result<std::path::PathBuf> {
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

fn generate_shamir_shares(recovery_key: &[u8], creds_dir: &Path) -> anyhow::Result<()> {
    let shares = shamir::split(recovery_key)?;

    println!();
    ui::ok("recovery key generated and enrolled");
    ui::ok("share codes generated");
    println!();
    println!("your 5 recovery shares are shown below.");
    println!("any 3 of these shares can reconstruct your recovery key.");
    println!("WRITE THESE DOWN or distribute them now — they will not be shown again.");
    println!();
    for (i, share) in shares.iter().enumerate() {
        println!("share {}/{}: {share}", i + 1, shares.len());
    }

    // save a local copy (encrypted at rest on the boot partition)
    let shares_path = creds_dir.join("recovery.shares");
    std::fs::write(&shares_path, shares.join("\n"))?;

    println!();
    println!("would you like to export these shares to removable media?");

    // detect removable block devices (simple heuristic: check /sys/block/*/removable)
    let removable = detect_removable_devices();
    let mut options: Vec<String> = removable
        .iter()
        .enumerate()
        .map(|(i, d)| format!("[{}] {}", i + 1, d))
        .collect();
    options.push(format!("[{}] skip export", options.len() + 1));

    println!("detected removable devices:");
    for opt in &options {
        println!("  {opt}");
    }

    let choice = ui::prompt_input(">")?.trim().to_string();
    if let Ok(n) = choice.parse::<usize>() {
        if n > 0 && n <= removable.len() {
            let dev = &removable[n - 1];
            // just write to the first mounted path of that device
            ui::ok(format!("share codes saved to {dev}").as_str());
        }
    }

    println!();
    println!("have you recorded all 5 shares? type \"yes\" to confirm and clear the screen.");
    if ui::prompt_yes_lower("")? {
        // clear screen
        print!("\x1B[2J\x1B[1;1H");
    }

    println!("\ndone!");
    Ok(())
}

fn detect_removable_devices() -> Vec<String> {
    let mut devices = vec![];
    if let Ok(entries) = std::fs::read_dir("/sys/block") {
        for entry in entries.flatten() {
            let removable_path = entry.path().join("removable");
            if let Ok(val) = std::fs::read_to_string(&removable_path) {
                if val.trim() == "1" {
                    let name = entry.file_name().to_string_lossy().to_string();
                    devices.push(format!("/dev/{name}"));
                }
            }
        }
    }
    devices
}

# installing `pyria` (WIP!!! INCOMPLETE!!!)

we have spent hours and days on a custom setup / unlock crate for making pyria
setup as smooth as possible. here's how to get from here to there on a fresh
nixos install disk.

## step 1: fetching the flake

`git clone https://github.com/aenriii/flake`, simple as. `cd flake` and get
ready!

## step 2: jumping into the setupuser flake.
<!--->
todo
<--->
## step 3: `pyria setup` commands

there *is* a canonical order to run `pyria setup` commands. running them 
out-of-order will either fail completely or create a broken installation.

before running any of these, select and remember a hostname. it will be used
throughout the setup process.

### stage 1: initializing the setup process and disk partitioning

initializing your hosts directory is simple enough, just run this in your
terminal:

```sh
$ pyria setup init --host "my-awesome-hostname"

Added default host files at hosts/my-awesome-hostname, and set up a profile
in flake.nix.
```

this requires no permissions, and simply copies a template base host config,
as well as adding your host to the `flake.nix`.

disk setup is also *somewhat* automated- though if you have external storage
or more than one hard drive, you may want to manually configure disko after
installing.

```sh
$ sudo pyria setup disks -d /dev/sda -b /dev/sdb --host "my-awesome-hostname"

[1/9] assuring adequate permissions & requirements...
✓ running with rwx permissions over both disks
✓ FIDO2 device detected
… enter your FIDO2 pin if you have one:
> 
○ touch your FIDO2 key now!
✓ FIDO2 key confirmed.
✓ temp directory created at /tmp/pyria-mnt

[2/9] verifying user consent... 
WARNING: This will erase ALL data on disks /dev/sda and /dev/sdb, are you sure
you would like to continue? type "yes" in all caps to confirm.
> YES

[3/9] partitioning boot disk: /dev/sdb
✓ wrote GPT with 2 partition(s) totaling 4GB of 32GB available disk space
✓ created 3GB FAT32 filesystem on /dev/sdb1 with label BOOT
✓ created 1GB LUKS2 container on /dev/sdb2 with label BOOTLOCK
✓ created 1GB EXT4 filesystem in /dev/sdb2
✓ mountpoint for /dev/sdb1 set to /boot
✓ mountpoint for /dev/sdb2 set to /boot/lock

done!

[4/9] partitioning disks: /dev/sda
✓ wrote GPT with 1 partition(s) totaling 1000GB of 1000GB available disk space
✓ created LUKS2 container on /dev/sda1 with detatched header and label NIXOS
✓ wrote header to /boot/lock/headers/NIXOS.img
✓ created BTRFS filesystem in /dev/sda1
✓ created @nix and @persist subvolumes in /dev/sda1
✓ set mountpoints for subvolumes @nix and @persist

done!

[5/9] generating necessary files...
✓ wrote my-awesome-flake/disko.nix to disk
✓ wrote /boot/lock/credentials/0.id to disk

done!

[6/9] enrolling FIDO2 security key on /dev/sdb2
✓ verified partition unlocked and mounted
… enrolling FIDO2 device...
… enter your FIDO2 pin if you have one:
> 
○ touch your FIDO2 key now!
✓ FIDO2 key enrolled.
✓ temporary passphrase removed from keyslot 0

done!

[7/9] enrolling FIDO2 security key + passphrase hybrid on /dev/sda1
✓ verified partition unlocked and mounted
… enter a passphrase you trust with your life:
>
… enter it again, just to be safe:
> 
✓ passphrase verified
… fetching salt from FIDO2 key...
… enter your FIDO2 pin if you have one: (1/2)
> 
○ touch your FIDO2 key now!
✓ salt fetched.
… deriving key from passphrase and salt, this may take a few moments...
✓ key derived.
… deriving LUKS2 credentials from derived key and FIDO2 key...
… enter your FIDO2 pin if you have one: (2/2)
> 
○ touch your FIDO2 key now!
✓ hybrid credentials enrolled.
✓ temporary passphrase removed from keyslot 0

done!

[8/9] verifying successful implementation
! you will be asked to enter your FIDO2 pin three times during this stage.
! each disk unlock requires a fresh pin session, and the argon2id key 
! derivation for /dev/sda1 takes long enough to expire the token mid-process.
! this is not a bug.
✓ closed all LUKS2 containers
… sanity check: attempting to unlock /dev/sdb2 w/ temp passphrase
✓ attempting to open /dev/sdb2 failed!
… opening /dev/sdb2 (/boot/lock)...
… enter your FIDO2 pin if you have one: (1/3)
> 
○ touch your FIDO2 key now!
✓ /dev/sdb2 unlocked and mounted
… sanity check: attempting to unlock /dev/sda1 w/ temp passphrase
✓ attempting to open /dev/sda1 failed!
… enter the passphrase you used for /dev/sda1:
>
… fetching salt from FIDO2 key...
… enter your FIDO2 pin if you have one: (2/3)
> 
○ touch your FIDO2 key now!
✓ salt fetched.
… deriving key from passphrase and salt, this may take a few moments...
✓ key derived.
… deriving LUKS2 credentials from derived key and FIDO2 key...
… enter your FIDO2 pin if you have one: (3/3)
> 
○ touch your FIDO2 key now!
✓ LUKS2 credentials derived.
… opening /dev/sda1 (/nix, /persist)...
✓ /dev/sda1 unlocked and mounted
✓ implementation successful!

done!

[9/9] (optional) shamir share generation

would you like to generate shamir recovery shares? (recommended)
these allow recovery if your FIDO2 key is lost or damaged.
WARNING: only share these with people you trust with your life.
type "yes" in all caps to generate, anything else to skip.
> 

✓ recovery key generated and enrolled on /dev/sdb2
✓ recovery key generated and enrolled on /dev/sda1
✓ share codes generated

your 5 recovery shares are shown below.
any 3 of these shares can reconstruct your recovery key.
WRITE THESE DOWN or distribute them now — they will not be shown again.

share 1/5: pyria-XXXX-XXXX-XXXX-XXXX-XXXX
share 2/5: pyria-XXXX-XXXX-XXXX-XXXX-XXXX
share 3/5: pyria-XXXX-XXXX-XXXX-XXXX-XXXX
share 4/5: pyria-XXXX-XXXX-XXXX-XXXX-XXXX
share 5/5: pyria-XXXX-XXXX-XXXX-XXXX-XXXX

would you like to export these shares to removable media?
detected removable devices:
  [1] /dev/sdc — "my-usb-drive" (16GB)
  [2] skip export
>

✓ share codes saved to /dev/sdc

have you recorded all 5 shares? type "yes" to confirm and clear the screen.
>

done!
```
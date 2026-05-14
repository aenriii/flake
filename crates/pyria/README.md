# `pyria` (binary), a custom tool for managing secure `nixOS` installations

this is a custom tool intended for the `pyria` flake that helps manage complex
actions, enables [hybrid enrollment](#hybrid-enrollment) and a nuke passphrase,
provides a `run0` wrapper that's a drop-in replacement for `sudo`, and wraps
`nix` management commands to ease the transition and experience for new users.

*this and a built iso also technically makes pyria its own distro, but don't tell
anyone <3*

it's built specifically for managing `pyria` installations, but we've taken the
steps necessary to make most of these commands as useful as possible in other
contexts as well. 

for example, we're going to be replacing `cryptsetup` with `pyria luks` commands
and `sudo` with `pyria sudo` commands in a live Arch installation before 
`pyria` is ready for deployment.

## cli usage

### `pyria luks [enroll|unenroll|lock|unlock|open|close|nuke] <mapper-name>`

this set of commands manage luks2 encryption, including standard and hybrid
enrollment, as well as unlocking and key management.

**arguments:**

  `-H --luks-header <header-file>`
  in cases of a detatched luks header, specify the path to the header file.

  `-b, --boot-drive <boot-drive>`
  specify the path to the boot drive. if `-H` is not specified, but this is, 
  the header file will be assumed to be at `<boot-drive>/luks2.header`

  `-r, --root-drive <root-drive>`: specify the path to the root drive.

  `--hybrid=fido2,tpm2`: enable hybrid enrollment using fido2 and/or tpm2.

  `<mapper-name>`: the name of the luks mapper to use. some commands only
  need either a mapper-name or a boot-drive/root-drive pair, some need both.

#### `pyria luks enroll [--nuke]`

this command initiates the luks2 encryption enrollment process, optionally
enrolling a nuke passphrase. if you specify `--nuke`, a nuke passphrase
will be enrolled. when entered during `luks unlock` or `luks open`, the
keyslots will be wiped clean and the device will be erased to the most feasible
degree.

this command requires a boot-drive/root-drive pair.

#### `pyria luks unenroll <keyslot>`

this command removes the passphrase from the specified keyslot.

this command requires a boot-drive/root-drive pair.

#### `pyria luks lock`

\[wip] this command is very similar to `cryptsetup luksSuspend`, but it is
not decided yet what the exact behavior should be.

this command requires a boot-drive/root-drive pair or a mapper-name.

#### `pyria luks unlock`

\[wip] this command is very similar to `cryptsetup luksResume`, but it is
not decided yet what the exact behavior should be. if you enter an enrolled nuke
passphrase, the keyslots will be wiped clean and the device will be erased to 
the most feasible degree.


this command requires a boot-drive/root-drive pair or a mapper-name.

#### `pyria luks open`

this command opens the luks device specified. if you enter an enrolled nuke
passpgrase, the keyslots will be wiped clean and the device will be erased to
the most feasible degree.

this command requires a boot-drive/root-drive pair.

#### `pyria luks close`

this command closes the luks device specified.

this command requires a mapper-name.

#### `pyria luks nuke [--doomsday] [--confirm]`

this command requires `--confirm` to be specified. otherwise, it will tell the
user to use `--confirm` to confirm the nuke operation. if `--doomsday` is specified,
all mounted luks devices will be nuked.

### `pyria setup [init|configure|disks|boot|hardware|install]`

this command helps walk you through the setup process for the flake, including
creating and configuring a host, selecting a kernel, and setting up user accounts.
there is a canonical order for these steps, and they are documented in that order.

#### `pyria setup init --hostname <hostname>`

this command copies a flake configuration template to a new hosts directory 
with the specified hostname.

#### `pyria setup configure --hostname <hostname>`

this command runs through an interactive configuration process for the specified
hostname, including selecting a kernel flavor and config, adding user accounts,
setting up specializations, and deciding your luks configuration.

#### `pyria setup disks --hostname <hostname> --boot-drive <boot-drive> --root-drive <root-drive>`

this command automatically partitions and formats disks for the specified 
hostname, including initial LUKS2 hybrid enrollment. during the setup process, 
TPM2 enrollment is disabled as the PCRs will immediately change once the system
is booted into.

it also generates a `disko.nix` file for your host based on a template, which
is used to generate an `/etc/fstab` configuration file.

#### `pyria setup boot --hostname <hostname>`

this command mounts the persistent disk for the specified hostname, and generates
and enrolls secure boot keys.

#### `pyria setup hardware --hostname <hostname>`

this command generates a hardware configuration file for the specified hostname
based on the currently running hardware. it also sets a few hardware-specific
security options (such as SME on AMD CPUs).

#### `pyria setup install --hostname <hostname>`

> note: before running this command, be sure to configure your user as you see
> fit in users/{user}/{default|home}.nix

this command wraps `nixos-install` to install the flake configuration for the
specified hostname.

### `pyria nix [upgrade|update|switch|pkg|rollback|generations|gc|maintenance]`

> these commands are still being mapped out architecturally, and dont have
canonical implementations yet, the following is a working draft.

these commands wrap `nix` and `nixos` commands to perform various nix-related
operations in a way that might seem more intuitive or user-friendly than the
default nix commands to a user who is not familiar with nix internals.

#### `pyria nix upgrade [--switch]`

this command attempts to pull the latest version of the flake from the remote
repository. if `--switch` is specified, it will also switch to the new version,
however considering this is normally used with `nix update` it is not enabled
by default.

#### `pyria nix update [--switch]`

this command updates all packages in the nix store to the latest version 
available. if `--switch` is specified, it will also switch to the new version,
however since this is normally used with `nix update` it is not enabled
by default.

#### `pyria nix switch`

this command switches to the latest generation of the flake, if one exists. it
is equivalent to `nixos-rebuild switch`

#### `pyria nix pkg [add|remove|list|search] [--user]`

these commands allow you to manage packages in the nix store. if `--user` is
specified, it will manage packages for the current user, otherwise it will
manage packages system-wide. pyria uses its own configuration files which are
imported by system-wide and user-specific nix configurations by default in 
order to provide a consistent package management experience.

#### `pyria nix rollback`

this command allows you to roll back to a previous generation of the flake, if one exists.

#### `pyria nix generations`

this command lists all generations of the flake, including their generation number and timestamp.

#### `pyria nix gc`

this command performs garbage collection on the nix store, removing unused 
packages and freeing up disk space.

#### `pyria nix maintenance`

this command performs maintenance tasks on the nix store, such as performing
a garbage collection run and cleaning up old package versions. it is typically
invoked as part of a systemd hook, but can be invoked manually. it also uses
`notify-send` to alert the user if they have available package updates or are
running out of disk space.

### `pyria vault [create|destroy|open|close|list|configure] <name>`

this command allows you to manage [vaults](./docs/crypto/vaults.md) easily.

#### `pyria vault create [-s <size>] [-f <fs>] <name>`

this command creates a new vault with the specified name and size (readable,
such as `10G`). if no size is specified, `10G` is used by default. if no
filesystem is specified, `btrfs` is used by default.

#### `pyria vault destroy <name>`

this command destroys the vault with the specified name.

#### `pyria vault open <name>`

this command opens the vault with the specified name.

#### `pyria vault close <name>`

this command closes the vault with the specified name.

#### `pyria vault list`

this command lists all known vaults available to the user.

#### `pyria vault configure <name> [mountpoint|expand] <...args>`

this command configures the vault with the specified name, using the specified
configuration option(s).

- **mountpoint**: configures the mountpoint for the vault. this defaults to
`~/mnt/<name>`. if the mountpoint does not exist, it will be created automatically.
- **expand**: expands the vault to the specified size (readable, such as `10G`).

#### `pyria vault rekey <name> <...args from luks enroll>`

this command rekeys the vault with the specified name, as if you were running
`pyria luks enroll` pointed at the vault and then unenrolling the previous key.

### `pyria sudo <...args>`

this command is a drop-in `sudo` replacement that converts the given sudo 
command into a valid `run0` command and executes it.
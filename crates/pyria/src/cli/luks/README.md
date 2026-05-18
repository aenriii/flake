## notes

everything needed (other than the actual authentication methods themselves, of
course) to unlock a pyria-configured LUKS2 container is stored in the respective
keyslot's metadata.

## luks device management

### `luks create [-H <header-file>] [--hw <fido2,tpm2>] [--hw-only] <device>`

- `--hw`: specifies the type of hardware credential(s) to enroll if necessary
- `--hw-only`: specifies that the credential should be enrolled only using hardware

Creates a new LUKS2 container and enrolls a credential into it.

### `luks open [-H <header-file>] <device> <name>`

Opens the LUKS2 container

### `luks close [-H <header-file>] <device> <name>`

Closes the LUKS2 container

## credential management

### `luks enroll [-H <header-file>] [--hw <fido2,tpm2>] [--hw-only] <device>`

Enrolls a new credential into the LUKS2 header.
- `--hw`: specifies the type of hardware credential(s) to enroll if necessary
- `--hw-only`: specifies that the credential should be enrolled only using hardware

Default behavior is to enroll a simple passphrase-only credential.

*unimplemented currently*

### `luks unenroll [-H <header-file>] <device> [<keyslot>]`

Unenrolls a key from `device`. If `keyslot` is not specified, the default
behavior is to open an interactive prompt to select the keyslot to unenroll.

*unimplemented currently*

### `luks nuke [-H <header-file>] [--confirm] <device>`

Nukes all keyslots from the LUKS2 container.

## luks suspend/resume

### `luks lock [-H <header-file>] <device> <name>`

Locks the LUKS2 container.

*unimplemented currently, this should work like `luksSuspend` but we aren't sure
what we want to do*

### `luks unlock [-H <header-file>] <device> <name>`

Unlocks the LUKS2 container.

*unimplemented currently, this should work like `luksResume` but we aren't sure
what we want to do*



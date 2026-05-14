# `pyria` documentation

this documentation goes deep into the design and implementation of `pyria`,
if you're just looking for a quick start / surface-level cli documentation,
look at the [README.md](../README.md)

## table of contents

<!--- [design principles](#design-principles)-->
- [assessing imported packages](#assessing-imported-packages)

### available pages

- [crypto/argon2id.md](crypto/argon2id.md) - this page provides an overview of 
how the argon2id algorithm is used in `pyria`.
- [crypto/hybrid-enrollment.md](crypto/hybrid-enrollment.md) - this page 
provides an overview of what "hybrid enrollment" is and the security benefits
it provides over traditional single-factor luks keyslot enrollment methods.
- [crypto/vault.md](crypto/vault.md) - this page provides an overview of 
"vaults", what they are, why they're useful, when to use one, where they go,
and how they work.

<!--## design principles
`pyria` is designed to be a simple, easy-to-use cli tool for managing secure
linux systems, configurable as needed using simple toml configuration. here
are some of the key design principles:

### -->

## assessing imported packages

`pyria` uses the following directly imported packages:

### cryptography

- `argon2` - this crate provides password hashing utilities using the argon2
algorithm. you can see how it's used in [`util/crypto/argon2id.rs`](../src/util/crypto/argon2id.rs)
and our default configurations with explanations in [crypto/argon2id.md](crypto/argon2id.md).
- `chacha20` - this crate provides cryptographically secure random number 
generation using the chacha20 algorithm. we prefer it over the default `rand`
crate due to the assurance of cryptographically secure random number generation.
- `hkdf` - this crate provides a simple interface for key derivation using the
HMAC-based Key Derivation Function (HKDF). we use it to derive keys at various
points in the `pyria` codebase.
- `sha2` - this crate provides a simple interface for hashing data using the
SHA-2 family of algorithms.
- `sharks` - this crate provides algorithms for splitting data into recoverable
shards using a shamir secret sharing scheme.
- `zeroize` - this crate provides a way to securely zero out memory, we use it
to automatically clear sensitive data from memory after use.
- `tss_esapi` - this crate provides a thin wrapper around the TPM2 ESAPI (TPM2
Enhanced System API) library, which we use to interact with TPM2 hardware devices.

### code cleanliness

- `anyhow` & `thiserror` - these crates provide error handling utilities that
make it easy to propagate errors up the call stack to a place where they can be
dealt with peacefully instead of crashing.
- `clap` - this crate provides a simple, declarative interface for defining
command-line interfaces. we use it to define the `pyria` cli interface.

### user experience

- `dialouger` - this crate provides a simple command-line input interface with
hidden input support for sensitive data, such as passwords.
- `indicatif` - this crate provides a simple interface for displaying progress
indicators in the terminal. we use it to show progress during key derivation and
other long-running operations.

### low-level libraries

- `fido2-rs` - this crate provides a simple interface for interacting with
FIDO2 security keys, such as YubiKeys. we use it to implement hardware-based
hybrid authentication for `pyria`.
- `libc` - this crate provides low-level bindings to the c standard library, we
use it to check for elevated privileges when needed, such as during partitioning.
- `libcryptsetup-rs` - this crate provides low-level bindings to the libcryptsetup
library, we use it to interact with LUKS2 devices.
- `nix` - todo

### miscellaneous

- `serde` - this is a standard-issue serialization library that we use to
read and write structured data where needed.
- `serde_json` - this crate provides a JSON backend for `serde`, it also allows
us to directly interact with data stored in LUKS2 headers.
- `tempfile` - this crate provides a simple interface for creating temporary
files and directories. (TODO)
- `tokio` - this crate provides an asynchronous runtime for Rust, we use it to
run asynchronous tasks and manage concurrency.






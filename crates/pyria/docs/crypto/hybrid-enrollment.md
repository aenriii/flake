# hybrid enrollment

## first off; what's "wrong" with single-factor luks keyslots?

truthfully, there is nothing inherently "wrong" with single-factor luks 
keyslots. they are secure in their own right, but they are not secure against
a sufficiently powerful threat actor.

as it stands, luks2 encryption typically only allows *one* method of
authentication per keyslot. whether that be a FIDO2 key or a passphrase,
each keyslot is bound by only one of these methods, and in a way that, compared
directly to properly configured hybrid enrollment, is outright insecure

let's take passphrases for instance; when using a passphrase, the key is
derived from the passphrase using parameters for `argon2id` that are fine-tuned
to hit around two seconds on the formatting machine's cpu. imagine your cpu. 
imagine *mine* (a ryzen 7 2700). now imagine a threadripper, or high-grade 
server cpus. the two seconds it takes on your device to derive the key from the
passphrase is going to end up taking half that time if not less on a 
sufficiently fast cpu. with GPU acceleration? the default 1GB of memory used by
luks2's default `argon2id` parameters fits perfectly, over and over again, even
in gpus from well over a decade ago that, despite the memory pressure of argon2,
can still be easily parallelized better than a CPU. 

when you understand it to that point, you realize that any sufficiently powerful
threat actor (a.k.a.someone with the $5k to get an old threadripper or rent GPU
compute) can brute-force the passphrase in a scary amount of time, typically at
least. for high-risk environments, this is simply not acceptable. journalists,
activists, anyone paranoid enough to sacrifice a little bit of boot speed and a
little bit of convenience for exponentially better security can use hybrid 
enrollment to potentially mitigate this threat.

## so then what *is* hybrid enrollment?

hybrid enrollment is a technique that combines multiple authentication methods
into a single secure, hardware-backed key. we utilize hardware HMAC, software
HKDF using hardware-backed salt values, and restrictively computationally
expensive argon2id functions to derive a 64-byte high-entropy key. depending on
what hardware devices are available, this key could be backed by anything from
the sanctity of your boot chain to a FIDO2 key that you keep on a keychain, or
both.

cryptographically combining these intermediate keys allows us to bind the 
encryption of your hard drive to un-cloneable hardware devices, making it 
practically impossible to unlock your drive without the full agreement of every
device involved *and* the correct passphrase.

in the possible case of all hardware devices being compromised by a threat
actor, we *still* make it prohibitively expensive to brute-force the passphrase.
by default, we calibrate our argon2id parameters based on your machine. we use
one third of your system's total memory (so for a 24GB system, 8GB), and then
we calibrate the number of iterations with a parallelism factor of 4 to achieve 
an unlock time around 45-60 seconds. this is done automatically using the `pyria
setup disks` command. the argon2id parameters are stored in the LUKS header and
are used every time you unlock your drive without forcing you to recalibrate.

the argon2id function gives us a cryptographically secure 64-byte key, which we
then use as the key material for HKDF, salted by the hardware-defined salt 
values, to obtain a final 64-byte key, which is used to unlock the drive.

45-60 seconds may sound like a long time, but in a doomsday scenario it could
make the difference to whether or not a large threat actor is capable of 
compromising your system. 

and if you upgrade your system and want to upgrade your ram configuration, 
you're always able to re-enroll your drive with a new configuration without
needing to reformat or reinstall your operating system. remember; the more RAM
you have and the better your hardware, the harder it is for a large threat 
actor to parallelize their attack.

when combined with a FIDO2 key, the argon2id cost becomes a secondary defense;
the primary protection is the uncloneable hardware secrets stored on your FIDO2
key. many FIDO2 devices enforce PIN retry limits and authentication rate 
limiting, making brute force attacks against the device itself impractical, 
even if they have access to the hardware device itself.

## what steps does the process actually take?

### when including a FIDO2 device

we begin by figuring out which device connected to the system is available. we
use the `fido2` crate to enumerate all connected devices and select the first
one that's available. if PIN support is available we prompt the user to set a
PIN for the device. if PIN support is *active* we prompt the user to enter the
PIN for the device.

on first use, we generate a credential on the FIDO2 device that is encrypted by
the device and stored in the boot partition. on subsequent uses, we just reuse
the credential. we use this credential, as well as the user's PIN, if one 
exists, to run a secure FIDO2 "assertion" against a static token, which HMACs 
the data against the FIDO2 device's internal unextractable secret. for this 
static token, we use `pyria:fido:client-data:v1` as the client data hash input
and `pyria` as the relying party ID. these are fixed constants; changing them
would produce a completely different HMAC output, so they must remain 
consistent across all pyria versions. this creates our FIDO2 key's 
hardware-backed salt.

### when including a TPM2 device

we begin by checking TPM2 availability, and if it is present, we start by 
creating a primary key using an identifier unique to pyria's TPM2 usage, 
`pyria:tpm2:primary:v1`. we do this every time we need to use the TPM2 device,
as the key is deterministically generated by the TPM2 device based on the
template and identifier we provide.


on enrollment, we first read the values of PCR 7, 9, and 11 from the TPM2
device. we concatenate and hash them, producing a unique PCR hash value that
we can use to verify the integrity of the boot process. we then create a "trial"
policy session to calculate a "policy digest," a cryptographic description of
the required boot state, using the PCR hash value as input. we ask the TPM2
device to create a permanent HMAC key, binding it to the policy digest so it can
only be used when the PCR values match. this key never leaves the chip, but we 
store the key blob (which lets the TPM2 device reconstruct the key context) in
the boot partition alongside the LUKS2 header. we then use the HMAC key to 
derive a hardware-backed salt using the unique constant value `pyria:tpm2:salt:v1`. 
because of the way the HMAC key is bound to the policy digest, the HMAC will
only succeed if the PCR values match the policy digest.

when we want to retrieve our salt, we create the same primary key, create a
real policy session which reads the current PCR values and verifies that they
match the policy digest the HMAC key is bound to. we ask the TPM2 to HMAC the same
constant value (`pyria:tpm2:salt:v1`). again, because of the way the HMAC key is
bound to the policy digest, we will only receive the same salt back if the PCR
values have not changed. if the PCR values have changed, the HMAC will fail.

### after gathering hardware salt(s)

if there are multiple salts available, we combine them using HKDF into a single
salt material. if only one is available, we use it directly. our next step is to
derive an intermediate key from our passphrase using argon2id. this intermediate
key is passed to a hardware device (such as a FIDO2 device) which uses its
internal unextractable secret to produce *another* intermediate key using HMAC.
we then use HKDF to derive the final key using the combined or single hardware
salt as the salt input and the intermediate key as the key material.

this final key is then used to unlock the LUKS2 device. every sensitive 
intermediate value is zeroed when it goes out of scope via the `Zeroizing` 
wrapper, and freed pages are zeroed by the kernel's `init_on_free` setting as 
an additional layer.

### what if there are no hardware salts available?

without hardware devices, we derive the salt from a random value generated at
enrollment and stored in the LUKS2 header. the security of this configuration 
relies on the computational cost of argon2id and the entropy of your passphrase
alone.

for better security without FIDO2 hardware, consider:
- using a separate keyfile on a third physical device
- network-bound disk encryption via tang
- obtaining a FIDO2 security key (recommended)

## how big of a security benefit does this even provide?

hybrid enrollment is not a permanent magic bullet against threat actors, but it
does make it *comparably* infeasible for a threat actor to gain access to your
encrypted disk without knowing your passphrase *and* having access to your
hardware device(s). 

using standard LUKS2 without hybrid enrollment or enhanced passphrase enrollment
means all your threat actor needs is a small GPU farm and time. using `pyria`
to enhance your passphrase with a stronger argon2id key derivation function
means the threat actor needs a lot more time, and a lot more GPU. enabling a
FIDO2 security key means the threat actor needs to have the FIDO2 key and the
associated PIN to brute-force your passphrase. *in case of this, i do recommend
investing in a FIDO2 device with a rate limit, the one i'm looking at requires
100ms in between attempts.* enabling TPM2 PCR bindings requires your exact
machine to exist in the boot state it was enrolled in to attempt to unlock the
disk. enabling both FIDO2 and TPM2 PCR bindings provides the strongest possible
security against threat actors, but requires careful setup and maintenance.

this doesn't protect against physical coercion, a seized unlocked running 
machine, an evil maid before setup, or a bad FIDO2 key. there are ways to
partially defend against many of these though; using both available hardware 
measures to partially mitigate a bad FIDO2 key and/or an evil maid attack, keep
your boot disk on a microSD card you keep on your person at all times to make
descruction immediately possible and hopefully avoid physical coercion, and
*turn your device off when not in use* to avoid leaving it unlocked.

nothing can be perfect, but we can get damn close.

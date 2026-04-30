# `pyria`, my own paranoid nixos config

## notes before installing

- this flake is hardened specifically for my hardware sets. currently that is a
second-generation ryzen (zen+) with no TPM and a Samsung EVO SSD with flawed
hardware encryption. you may need to edit these files to add more things for
what your hardware supports. always feel free to upstream your changes!
- the `gaming` specialization is specifically configured to run overwatch. im
not kidding. with this nixos install, overwatch becomes my biggest security
threat.
- there is a `config.hostprofile` option called `noCompromises`. this option
is not recommended for day-to-day use. you can expect a 50-75% slowdown on any
modern cpu by using this, as it disables SMT, enables SLUB debug consistency
checks, each of which typically have an up to 50% slowdown, and has a plethora
of other sacrificing-performance-for-security settings enabled.

## optional-ish auxillary hardware

there are two hardware pieces that are **required** for the using the higher
security `paranoid.nix` luks configuration;

- a FIDO2 security key. i'm looking at the [Token2 Pin+ Dual Release 3.3](https://www.token2.com/shop/product/pin-dual-release3-fido2-1-key-with-openpgp-and-otp-and-dual-usb-ports), it has higher security specs than yubikeys and is far cheaper.
- a removable storage medium you trust with your life. i'm looking at a [Samsung PRO Endurance 32GB MicroSD card](https://www.samsung.com/us/computing/memory-storage/memory-cards/microsdhc-pro-endurance-memory-card-w-adapter-32gb-mb-mj32ga-am/) and a [Cotchear MINI](https://www.amazon.com/dp/B07HFQQ71F)

### what the fuck do you mean a microsd card?

high-endurance microsd cards are typically spec'ed better for longevity than 
consumer usb drives. this alone makes them a desirable target for this kind of
paranoid setup, but they have the added benefit of being easier to take out of
an adapter and eat if shit *really* hits the fan. this is your last resort.

# a security walkthrough

## page 1: hardening the boot process

**important: this page follows the boot process used in `luks/paranoid.nix`**

the boot process for most linux installs are highly insecure. most 
configurations today skip secure boot, have unencrypted kernel files, or are
otherwise susceptible to maid attacks, kernel swaps, or fake modules. we solve
this using a variety of tools that are meant to make breaking the boot process
as close to impossible as feasible.

### stage 0 paranoia: standard mitigations

as far as standard mitigations go, `lanzaboote` is used for secure boot setup,
`sbctl` keys are properly enrolled if you follow [INSTALL.md](./INSTALL.md), 
and LUKS2 encrypts your drive, requiring various verification methods in order
to access your files. kernel verification is assured by secure boot in order to
prevent tampering.

### stage 1 paranoia: a detatched LUKS2 header

when using the `luks/paranoid.nix` configuration, your LUKS2 header is actually
not stored on your disk. that's that "removable storage medium you trust with
your life" part of the hardware requirements. your header is stored on a ext4
partition on this external storage, meaning you need to have it plugged in to 
boot. this means your decryption keys move with you (or more, with the external
storage, but keeping it on a keychain is good practice!).

### stage 2 paranoia: FIDO2 key enrollment & hard lockout

after first boot setup (see [INSTALL.md#First Boot](./INSTALL.md#First%20Boot)),
booting requires the external storage with the LUKS header, a passphrase, *and*
a FIDO2 security key to decrypt your hard drive and boot. this key should also
live on your keychain. you might want to invest in a trustable usb hub!

we also implement a hard lockout after 10 failed FDE decryption attempts. 
we store the count of attempts in a plaintext file within the same partition
which holds your primary LUKS2 header. quite a simple script, but inconvenient
if not genuinely difficult to crack. gradual backoff of `2 ** (COUNT - 3)` secs
starts after 3 failed attempts. once you fail the 10th time, the boot script
locks you out, and you have to mount the external storage to another computer
and manually remove the count file to continue attempting to unlock the 
computer.

### stage 3 paranoia: failsafe-encrypting your LUKS2 header.

your LUKS2 header is stored as a binary file on an ext4 partition on the
external storage. technically, anyone with physical access could easily clone
this and have infinite tries to boot. we solve this issue by LUKS2 encrypting
the ext4 partition with a temporary passcode, then on first boot we remove the
passcode in favor of the FIDO2 key. these are unclonable. this may seem like it
degrades UX significantly, but the decryption should be seamless if you have
your FIDO2 key inserted when you boot. this also protects your lockout counter
with that same encryption, as it sits on the same partition right beside your 
LUKS2 header.

### the boot process, in chronological order;

1. **UEFI -> Bootloader**
the bootloader is verified using Secure Boot, and subsequently loaded.
2. **Bootloader loads available boot options**
the available boot options (for instance, the standard `hardened` mode vs the 
`gaming` specialization) are displayed using `lanzaboote`. you are given the
option to select either of these, or one of the nixos-given rollbacks (incase
an update breaks your system in some way).
3. **Bootloader -> Kernel**
the bootloader hands off control to the kernel. thus, a beautiful baby linux
is born.
4. **Decrypting your LUKS header**
the kernel uses your FIDO2 key to decrypt the LUKS2 partition holding your main
install's LUKS2 header.
5. **Decrypting your main drive**
your FIDO2 key *and* a unique, secure passphrase entered at runtime are used to
decrypt your main drive, allowing the boot to progress.

### optional failsafe: shamir shares

optionally, on first boot, a 3/5 shamir share can be generated as a last-ditch
recovery effort. **only generate these keys and share them if you have 
ride-or-die people you would trust with every single file on this hard drive.
without proper assurances, these could be used against you. store them in
different jurisdictions, different countries if possible.**

## page 2: hardening the kernel

### selecting kernelConfig and kernelFlavor

for easier kernel picking-and-choosing, we have `config.hostprofile`, with
these options:

```nix
hostprofile = {
  # whether or not to use the system's TPM 2.0+ module to bind the LUKS key of
  # the primary drive within the pc to PCR 7 and PCR 9. Also includes userspace
  # scripts to disable the binding.
  hasTPM2 = false;
  # enforces kernelFlavor = "hardened" and kernelConfig = "fortress", and
  # enables various security-at-all-costs settings across the flake.
  noCompromises = false;
  # the kernel flavor to use. "default" pulls the latest mainline kernel from
  # nixos' repos. "hardened" locally compiles the latest release of 
  # linux-hardened.
  kernelFlavor = "hardened";
  # the kernel config set to use. 
  # - "loose" disables a few security features in favor of being able to run
  #   things such as Steam and Overwatch (certain requirements are imposed by 
  #   steam & proton-battleye that other configs do not follow.)
  # - "common" is a common secure configuration, without many of the slightly
  #   performance-losing config options.
  # - "hardened" is a daily-drivable secure configuration, sacrificing some
  #   performance for security
  # - "fortress" is a highly secure configuration which disables SMT & enables
  #   the "F" flag for kernel parameter "slab_debug", among other things.
  kernelConfig = "hardened";
}
```

### `"common"` kernel configuration

####  kernel parameters

- `init_on_alloc/init_on_free=1` - zero out memory when its allocated or freed,
this mitigates use-after-free bugs wrt leaking old data
- `slab_nomerge` - the kernel normally merges "slab caches" with similar sizes
to save memory, merging creates possible exploitation paths. this disabled that
feature.
- `randomize_kstack_offset=on` - randomizes the kernel stack offset on every
syscall. this makes stack-based kernel expoits much harder to aim.
- `pti=on` - page table isolation, the meltdown fix. keeps kernel page tables
out of userspace.
- `spectre_v2=on` - spectre variant 2 mitigation
- `mds=full` - mitigates microarchitectural data sampling, preventing a class
of bugs that leak data across cpu boundaries.
- `kvm.nx_huge_pages=force` forces NX bits on KVM huge pages, mitigating the
iTLB multihit vulnerability.
- `amd_iommu=on`, `iommu.strict=1`, `iommu.passthrough=0` - enables amd iommu
in strict mode, devices can only DMA to memory they're explicitly allowed to
access. prevents a compromised/malicious device from reading arbitrary memory.
- `efi=disable_early_pci_dma` - disables pci dma prior to iommu initialization,
preventing early-boot malicious/compromised devices from reading arbitrary 
memory.
- `mem_encrypt=on` enables memory encryption. for my amd machine, this is SME,
my bios supports TSME so this is redundant but it's nice to explicitly opt-in.
- `random.trust_cpu=off` - we refuse to exclusively trust the cpu for entropy,
opting to include `jitterentropy_rng` as an initrd module to help.
- `random.trust_bootloader=off` we also refuse to trust the bootloader for
entropy.
- `vsyscall=none` - removes the vulnerable legacy syscall mechanisms.
- `debugfs=off` - explicitly disables debugfs, which typically exposes a lot of
internal kernel information
- `module.sig_enforce` - block all unsigned modules. 
- `lockdown=` - here for posterity, hardened and gaming have different settings.

#### sysctl parameters

- `vm.mmap_rnd_bits/compat_bits` - sets the maximum ASLR entropy for memory 
mappings
- `vm.mmap_min_addr` - prevents mapping the zero page, eliminating null pointer
dereference exploits.
- `kernel.kptr_restrict=2` - hides kernel pointers from all users incl root
- `kernel.dmesg_restrict=1` - only root can read `dmesg`
- `kernel.printk="3 3 3 3"` - limits what kernel messages get printed to the 
console
- `kernel.kexec_load_disabled=1` - disables `kexec`, which would normally allow
for runtime kernel-swapping.
- `kernel.core_pattern="|/bin/false"` - core dumps get silently discarded
- `fs.suid_dumpable=0` - setuid programs dont produce core dumps to begin with
- `net.core.bpf_jit_harden=2` - hardens the BPF JIT compiler, reducing its
attack surface.
- `vm.unprivileged_userfaultfd=0` - restricts `userfaultfd` syscall to root,
mitigates some heap exploit techniques.
- `fs.protected_hardlinks/symlinks=1` - prevents hard/symlink-based TOCTOU 
attacks
- `fs.protected_regular/fifos=2` - extends the above protection to regular/fifo
files. also prevents privilege escalation via O_CREAT.
- `dev.tty.ldisc_autoload=0` - disables automatic TTY line discipline module
loading. obscure attack surface, but doesnt hurt to be comprehensive
- `kernel.sysrq=4` - only allow `sync` sysrqs 
- `kernel.randomize_va_space=2` - full ASLR, randomizes where things live in 
memory

*network-specific sysctl params, these often apply to both ipv4 and ipv6*
- `tcp_rfc1337=1` - protects against TIME-WAIT assassination attacks
- `tcp_syncookies=1` - prevents SYN floods
- `tcp_timestamps=0` - disables TCP timestamps, which can aid fingerprinting
- `accept/secure/send_redirects=0` block all attempts for redirects, prevents
many ICMP attacks that can hijack routing
- `accept_source_route=0` - disables source routing / ip spoofing method
- `rp_filter=2` - verifies that incoming packets could've come from where they 
claim
- `log_martians=1` - log packets with impossible source addresses
- `net.ipv6.use_tempaddr=2` - uses temporary randomized address instead of
mac-derived address
- `net.ipv6.accept_ra=0` - don't accept router advertisements. these can
redirect all traffic.

### `"loose"` kernel configuration

everything in `"common"`, *and*

#### kernel parameters

- `lockdown=integrity` - blocks unsigned modules and kernel modifications,
among some other things.

#### sysctl parameters

- `kernel.yama.ptrace_scope=1` - processes can ptrace child processes
- `kernel.perf_event_paranoid=1` - restricts `perf` event visibility less
- `kernel.unprivileged_userns_clone=1` - explicitly enables unpriviliged user
namespaces, steam uses these.
- `kernel.unprivileged_bpf_disabled=0` - explicitly enables unprivileged bpf
modules, which are used by some games.

### `"hardened"` kernel configurations

everything in `"common"`, *and*

#### kernel parameters

- `page_alloc.shuffle=1` - randomizes the free page list. makes some kinds of
attacks significantly harder
- `spec_store_bypass_disable=on` - spectre v4 mitigation. costs some performance,
which is why its hardened only.
- `lockdown=confidentiality` - kernel lockdown mode; everything `integrity`
blocks + blocking `/dev/mem`, raw disk access, hibernation, etc. basically a 
catch-many for blocking kernel memory leaks/unauthorized writes
- `oops=panic` - if the kernel hits an oops, panic instead of continuing. if an
oops occurs, more likely than not your system is more vulnerable. panicing is a
failsafe against that.
- `slab_debug=ZP` - enables red zones and poisoning for the kernel slab 
allocator. 
#### sysctl parameters

- `kernel.yama.ptrace_scope=3` - nobody can ptrace *anything*
- `kernel.unprivileged_userns_clone=0` - disables unprivileged user namespaces.
- `kernel.perf_event_paranoid=3` - restricts `perf` event visibility
- `kernel.unprivileged_bpf_disabled=1` - only root can load BPF programs

### `"fortress"` kernel configurations

> note: expect a system slowdown of 50-75% while using this kernel 
> configuration. this disables simultaneous multithreading and enables an
> expensive `slab_debug` flag which sanity-checks *every slab allocation ever*.
> each of these can have performance hits anywhere from 30-50%. 

everything in `"common"`, *and*

#### kernel parameters

- `page_alloc.shuffle=1` - randomizes the free page list. makes some kinds of
attacks significantly harder
- `spec_store_bypass_disable=on` - spectre v4 mitigation. costs some performance,
which is why its hardened only.
- `lockdown=confidentiality` - kernel lockdown mode; everything `integrity`
blocks + blocking `/dev/mem`, raw disk access, hibernation, etc. basically a 
catch-many for blocking kernel memory leaks/unauthorized writes
- `oops=panic` - if the kernel hits an oops, panic instead of continuing. if an
oops occurs, more likely than not your system is more vulnerable. panicing is a
failsafe against that.
- `slab_debug=FZP` - enables debug consistency checks, red zones, and poisoning
for the kernel slab allocator. do not pass go, immediately lose 50-70% of your
system performance
- `nosmt` - completely disable simultaneous multithreading. do not pass go,
immediately lose 30-50% of your cpu performance.
- `mds=full,nosmt` - mitigates MDS, explicitly flushes relevant buffers on
every kernel -> user transition. performance loss from l1tf is diminished via
nosmt
- `l1tf=full,nosmt` - mitigates L1 terminal faults (a.k.a. Foreshadow), flushes
the L1 data cache on each kernel -> user transition. performance loss from l1tf
is diminished via nosmt.

#### sysctl parameters

- `kernel.yama.ptrace_scope=3` - nobody can ptrace *anything*
- `kernel.unprivileged_userns_clone=0` - disables unprivileged user namespaces.
- `kernel.perf_event_paranoid=3` - restricts `perf` event visibility
- `kernel.unprivileged_bpf_disabled=1` - only root can load BPF programs


### blacklisted modules

the following modules have been blacklisted, they have fallen out of use and
are often ripe with CVEs, and have a large attack surface
```
  "dccp" "sctp" "rds" "tipc"
  "n-hdlc" "ax25" "netrom" "x25"
  "rose" "decnet" "econet" "af_802154"
  "ipx" "appletalk" "atm" "can"
```

## page 3: hardening userspace

we also put a lot of work into hardening userspace. this section & userspace
hardening overall is a work in progress, but we've made tremendous progress so
far.

### general hardening

#### swap `sudo` for `sudo-rs`

reduces the attack surface of the most widely used `setuid` binary by replacing
it with a rust alternative. we #love #rust!

#### FIDO2 key support is integrated into userspace

fairly simple, really, its probably best that your passkeys are stored on an
uncloneable device.

#### usbguard + usb killswitch is implemented

firstly, a udev rule monitors the device which holds your nixos partition's
header, a block device named `NIXHEADER`. if that device is physically removed,
your system immediately discards the decryption keys and forces a shutdown.

we also have usbguard enabled in block-first mode. currently, all usb devices
other than human-interface devices such as a keyboard and mouse are blocked 
immediately. this stops various attempts at physical access based attacks.

### systemd hardening

#### core dumps are disabled.

this prevents any form of data leak which happens by virtue of eating the data
contained in a core dump.

#### emergency mode is disabled

this makes the system a little less stable, but it is well worth it. an attacker
cannot simply gain a root shell on your system by just making the boot process
crash anymore, however this does mean that system recovery becomes a severe
headache if worst comes to worst.

#### **(todo)** every included systemd service is hardened

we are going to take a fresh install, look at all the systemd services, and
add a basic hardening template to each of them. this means that those services
are less vulnerable, but you should always check this for yourself *and* add
hardening configurations to any services you install.

### nix (daemon) hardening

#### all derivations are sandboxed

we enable `nix.settings.sandbox` in order to assure that no derivations can
peek into the currently running system. this ensures that no derivation can
do things such as read files outside the sandbox or access the network during
compilation.

### package signatures are enforced

all packages downloaded from the nixos cache have their signature verified
on-device, this prevents threat actors from simply replacing the package we get.

### trusted/allowed users are generated from the `wheel` group

only members of the `wheel` group can connect to the nix daemon or perform
builds.

### impermanence / filesystem hardening

#### the root file system is `tmpfs`

this wipes any non-persisted areas of your disk, preventing any bad actor from
simply slipping in some malicious binary in a way which persists on reboot.

#### `/tmp` is *actually* temporary

this seems like it would be common, and generally it is, but it is nice to
point out that `/tmp` is mounted as a `tmpfs`.

#### `/proc` is hardened

`/proc` is mounted with `hidepid=2`, so users can only see their own processes,
in case the other mitigations we have against this all fail.

#### only necessary system-level files are persisted by impermanence

logs, machine identity, networkmanager connections, etc are the only things 
preserved in its entirety.

#### user-level files are persisted in a separate LUKS-encrypted volume

*note: this is a WIP feature*

each user's persistent data (such as browser profiles, ssh keys, etc) lives
inside a LUKS-encrypted container stored on the persistence drive. that 
container is automatically unlocked by `pam_mount` when the user logs in, using
their normal password (and optionally FIDO2 key). inside, only the files and 
directories explicitly listed within home-manager's impermanence configuration
are kept. the remainder of the home directory is a `tmpfs` that vanishes on 
reboot. this means a user's secrets are never written to disk in plaintext,
and even an attacker who compromises the running system can't read another 
user's persistent data without knowing their password.

we also have file protection policies set up to where no regular user can see
any of the container files on /persist, reducing the attack area for
exfiltration and store-now-decrypt-later attacks.

this also means that having a separate user for any loosened configuration is
absolutely essential. even if that kernel is compromised there is no way to
actually open any sensitive user data, as it is still LUKS-backed.

to ration storage, we also create all per-user home containers and nested
vaults as sparse files, so they only use the disk space actually written.
the user container's virtual size acts as a per-user quota.

### userspace network hardening

#### DoT is enforced for all non-tailscale DNS lookups.

we use a simple `systemd-resolved` configuration to require all DNS lookups go
through a DoT tunnel. by default, this uses dns.quad9.net. plaintext dns is
*completely* disabled for non-tailscale DNS lookups.

#### tailscale's magicdns is scoped and can't poison system dns

we have tailscale enabled with `--accept-dns=false`, disabling tailscale's
typical system-level dns override. we instead do this ourselves, adding a
systemd network configuration to the `tailscale0` network specifiying that
magicdns is only to be used for urls ending in `ts.net`, this prevents it
from poisoning the entire system's dns.

#### `nftables` is highly restrictive.

we plan to add `opensnitch` to our network stack, but until then we rely 
entirely on `nftables`. right now, we disable all incoming TCP and UDP ports,
this is only altered by tailscale adding its own UDP port to the allowlist.

#### time synchronisation is secured

we replace `systemd-timesyncd` with `chrony` and force it to use NTS, which
encrypts the synchronisation data and authenticates the server, preventing
some large threat actor from feeding your system false time data, which could
break certificate verification in a plethora of places.

two servers are configured, with the option `minsources 2` set to ensure a
consensus.

#### local network discoverability has been lowered

we disabled `CUPS`, `avahi`, and `bluetooth` in order to reduce the attack
surface experienced from local network discoverability.

### system-level userspace hardening

#### strict PAM delays

failed login, sudo, and greetd attempts are delayed by 4 seconds, making
brute-force attacks extremely slow.

#### user resource limits

each user has a soft limit of 1024 processes and a hard limit of 8192 processes

#### runtime kernel module loading is disabled

this prevents even any root-privileged user from adding any module to the
kernel after the boot has completed. this prevents any plethora of attacks on
otherwise vulnerable machines or machines with compromised credentials.

#### grapheneos' `hardened_malloc` replaces glibc's `malloc`

`hardened_malloc` is far more hardened against various attack vectors than
glibc, and so we've swapped it in as the system-wide allocator. this may break
some programs. any included programs that have this issue have had their
allocator reverted.

#### `dbus-broker` is used over `dbus-daemon`

`dbus-broker` is widely regarded as a faster, more reliable, and more secure
dbus implementation. for that reason we have selected it over other options.

#### auditing is active, and very dense.

we have `auditd` enabled, and we're logging just about everything we can get
our hands on. from any attempts to run module adding/removing binaries, to any
opened/closed connections, to every privilege change.

#### SMT is optionally disabled

this clears out most of the remaining attack surface of sibling threads. SMT
is only disabled when `hostprofile.noCompromises` is set to `true` or 
`kernelConfig` is set to `"fortress"`

### application-level hardening (apparmor)

firstly, apparmor is enabled and set to kill any unconfined process that could
have a profile. this means that once a profile is assigned to a program, any
child process of that program that tries to run without a profile is immediately
terminated. 

work is ongoing to write strict `enforce`-mode profiles for many common 
applications. dbus mediation will be activated once profiles are ready.
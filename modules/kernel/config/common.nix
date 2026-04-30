{ ... }:
{
  boot.kernelParams = [
    "init_on_alloc=1"
    "init_on_free=1"
    "slab_nomerge"
    "randomize_kstack_offset=on"
    "vsyscall=none"
    "debugfs=off"
    "module.sig_enforce"
    "amd_iommu=on"
    "iommu.strict=1"
    "iommu.passthrough=0"
    "mem_encrypt=on"
    "pti=on"
    "spectre_v2=on"
    "efi=disable_early_pci_dma"
    "random.trust_cpu=off"
    "random.trust_bootloader=off"
    "kvm.nx_huge_pages=force"
    "mds=full"
  ];
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.randomize_va_space" = 2;
    "kernel.kexec_load_disabled" = 1;
    "kernel.core_pattern" = "|/bin/false";
    "kernel.printk" = "3 3 3 3";
    "kernel.sysrq" = 4;
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.default.log_martians" = 1;   
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.default.use_tempaddr" = 2;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 2;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_regular" = 2;
    "fs.protected_fifos" = 2;
    "fs.suid_dumpable" = 0;
    "vm.unprivileged_userfaultfd" = 0;
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
    "vm.mmap_min_addr" = 65536;
    "vm.swappiness" = 1;
    "dev.tty.ldisc_autoload" = 0;
  };
  boot.blacklistedKernelModules = [
    "dccp" "sctp" "rds" "tipc"
    "n-hdlc" "ax25" "netrom" "x25"
    "rose" "decnet" "econet" "af_802154"
    "ipx" "appletalk" "atm" "can"
  ];
  boot.initrd.kernelModules = [ "jitterentropy_rng" ];
  
  

}
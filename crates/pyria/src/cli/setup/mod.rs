use clap::Subcommand;

pub mod boot;
pub mod configure;
pub mod disks;
pub mod hardware;
pub mod init;
pub mod install;
pub mod user;

#[derive(Subcommand)]
pub enum SetupCommand {
    /// initialize a new host directory from the template
    Init {
        /// hostname for the new host configuration
        #[arg(long)]
        host: String,
    },
    /// interactive configuration wizard for a host
    Configure {
        #[arg(long)]
        host: String,
    },
    /// partition and encrypt disks, enrolling FIDO2 hybrid credentials
    Disks {
        #[arg(long)]
        host: String,
        /// data (root) drive — will be fully erased
        #[arg(short = 'd', long)]
        data_drive: String,
        /// boot drive (USB) — will be fully erased
        #[arg(short = 'b', long)]
        boot_drive: String,
    },
    /// mount persistent disk and generate/enroll secure boot keys
    Boot {
        #[arg(long)]
        host: String,
    },
    /// generate hardware configuration for the current machine
    Hardware {
        #[arg(long)]
        host: String,
    },
    /// run nixos-install for the given host
    Install {
        #[arg(long)]
        host: String,
    },
    /// set up a user account on the host with an optionally encrypted home directory
    User {
        #[arg(long)]
        host: String,
        #[arg(short = 'u', long)]
        username: String,
    },
}

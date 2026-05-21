use clap::Parser;
use pyria::cli::{Cli, Commands, luks::LuksCommand};

// #[cfg(feature = "full")]
// use pyria::cli::setup::SetupCommand;

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Luks { command } => match command {
            LuksCommand::Create { device, name, luks_header, hw, hw_only } => {
                pyria::cli::luks::create::run(
                    &device,
                    name.as_deref(),
                    luks_header.as_deref(),
                    hw.as_deref(),
                    hw_only
                )
            }
            LuksCommand::Enroll { device, luks_header, hw, hw_only } => {
                pyria::cli::luks::enroll::run(
                    &device,
                    luks_header.as_deref(),
                    hw.as_deref(),
                    hw_only,
                )
            }
            LuksCommand::Open { device, luks_header, name } => {
                pyria::cli::luks::open::run(&device, name.as_deref(), mount_point.as_deref(), mount_options.as_deref(), no_mount, luks_header.as_deref())
            }
            LuksCommand::Close { device } => {
                pyria::cli::luks::close::run(&device)
            }
            LuksCommand::Nuke { device, luks_header, confirm } => {
                pyria::cli::luks::nuke::run(&device, luks_header.as_deref(), confirm)
            }
            LuksCommand::Unenroll { device, keyslot, luks_header } => {
                pyria::cli::luks::unenroll::run(&device, luks_header.as_deref(), keyslot)
            }
            LuksCommand::Lock { device } => {
                pyria::cli::luks::lock::run(&device)
            }
            LuksCommand::Unlock { device } => {
                pyria::cli::luks::unlock::run(&device)
            }
        },

        // #[cfg(feature = "full")]
        // Commands::Setup { command } => match command {
        //     SetupCommand::Init { host } => pyria::cli::setup::init::run(&host),
        //     SetupCommand::Configure { host } => pyria::cli::setup::configure::run(&host),
        //     SetupCommand::Disks { host, data_drive, boot_drive } => {
        //         pyria::cli::setup::disks::run(&host, &data_drive, &boot_drive)
        //     }
        //     SetupCommand::Boot { host } => pyria::cli::setup::boot::run(&host),
        //     SetupCommand::Hardware { host } => pyria::cli::setup::hardware::run(&host),
        //     SetupCommand::Install { host } => pyria::cli::setup::install::run(&host),
        //     SetupCommand::User { host, username } => pyria::cli::setup::user::run(&host, &username),
        // },

        Commands::Sudo { args } => pyria::cli::sudo::run(args),
    }
}

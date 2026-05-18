use clap::{Parser, Subcommand};

pub mod luks;

#[derive(Parser)]
#[command(name = "pyria", about = "pyria — paranoid nixos setup and disk encryption tool")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// manage LUKS2 key enrollment and unlocking
    Luks {
        #[command(subcommand)]
        command: luks::LuksCommand,
    },
}
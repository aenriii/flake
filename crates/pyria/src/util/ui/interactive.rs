use std::io::{self, Write};

use dialoguer::{Input, Password};


pub fn prompt_input(msg: &str) -> anyhow::Result<String> {
    Ok(Input::new().with_prompt(msg).interact_text()?)
}

pub fn prompt_passphrase(msg: &str) -> anyhow::Result<String> {
    Ok(Password::new().with_prompt(msg).interact()?)
}

pub fn prompt_passphrase_confirm(msg: &str) -> anyhow::Result<String> {
    Ok(Password::new()
        .with_prompt(msg)
        .with_confirmation("enter it again, just to be safe", "passphrases did not match")
        .interact()?)
}

pub fn prompt_yes_caps(msg: &str) -> anyhow::Result<bool> {
    print!("{msg}\n> ");
    io::stdout().flush()?;
    let mut line = String::new();
    io::stdin().read_line(&mut line)?;
    Ok(line.trim() == "YES")
}

pub fn prompt_yes(msg: &str) -> anyhow::Result<bool> {
    print!("{msg}\n> ");
    io::stdout().flush()?;
    let mut line = String::new();
    io::stdin().read_line(&mut line)?;
    Ok(line.trim().eq_ignore_ascii_case("yes"))
}

pub fn prompt_select(msg: &str, options: &[&str]) -> anyhow::Result<usize> {
    Ok(dialoguer::Select::new()
        .with_prompt(msg)
        .items(options)
        .interact()?)
}

pub fn prompt_multiselect(msg: &str, options: &[&str]) -> anyhow::Result<Vec<usize>> {
    Ok(dialoguer::MultiSelect::new()
        .with_prompt(msg)
        .items(options)
        .interact()?)
}

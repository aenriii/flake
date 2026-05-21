use std::os::unix::process::CommandExt;
use pyria::ui;

fn main() -> anyhow::Result<()> {
    let args = std::env::args().collect::<Vec<_>>();
    run(args)
}

pub fn run(mut args: Vec<String>) -> anyhow::Result<()> {
  if args[0].contains("sudo") {
    let _ = args.remove(0);
  }
  let run0_args = translate(args)?;

  let err = std::process::Command::new("run0")
    .args(&run0_args)
    .exec();

  Err(anyhow::anyhow!("failed to exec run0: {err}"))
}

fn translate(args: Vec<String>) -> anyhow::Result<Vec<String>> {
    let mut out: Vec<String> = Vec::new();
    let mut iter = args.into_iter().peekable();
    let mut in_command = false;

    while let Some(arg) = iter.next() {
        if in_command {
            out.push(arg);
            continue;
        }

        if arg == "--" {
            out.push("--".to_string());
            in_command = true;
            continue;
        }

        if !arg.starts_with('-') {
            // start of the command, insert separator before it
            out.push("--".to_string());
            out.push(arg);
            in_command = true;
            continue;
        }

        // -u / -uUSER: run as user (same flag in run0)
        if let Some(val) = valued_flag(&arg, 'u') {
            let user = val.map(Ok).unwrap_or_else(|| {
                iter.next().ok_or_else(|| anyhow::anyhow!("-u requires a username"))
            })?;
            out.push("-u".to_string());
            out.push(user);
            continue;
        }

        // -g / -gGROUP: run as group (same flag in run0)
        if let Some(val) = valued_flag(&arg, 'g') {
            let group = val.map(Ok).unwrap_or_else(|| {
                iter.next().ok_or_else(|| anyhow::anyhow!("-g requires a group name"))
            })?;
            out.push("-g".to_string());
            out.push(group);
            continue;
        }

        match arg.as_str() {
            // direct equivalents
            "-i" => out.push("-i".to_string()),

            // close equivalents
            "-s" => out.push("--via-shell".to_string()),
            "-n" => out.push("--no-ask-password".to_string()),

            // preserve environment: expand current env into --setenv flags
            "-E" => {
                for (k, v) in std::env::vars() {
                    out.push(format!("--setenv={k}={v}"));
                }
            }

            // sudo-only flags with no run0 equivalent
            "-H" => ui::warn("-H is not needed with run0, HOME is managed by the system"),
            "-k" | "-K" => {
                ui::warn(&format!("{arg}: credential timestamps don't apply to run0, ignoring"))
            }
            "-v" => ui::warn("-v: credential validation doesn't apply to run0, ignoring"),
            "-b" => ui::warn("-b: background execution has no run0 equivalent, ignoring"),

            // not supported
            "-l" | "-ll" => {
                anyhow::bail!("-l: permission listing is not supported — check polkit rules instead")
            }

            // pass unknown long flags through to run0 unchanged
            _ if arg.starts_with("--") => out.push(arg),

            _ => anyhow::bail!("unrecognized sudo flag: {arg}"),
        }
    }

    Ok(out)
}

/// Returns `Some(Some(value))` if `arg` is `-cVALUE`, `Some(None)` if it is exactly `-c`,
/// or `None` if `arg` does not start with `-c`.
fn valued_flag(arg: &str, c: char) -> Option<Option<String>> {
    let mut chars = arg.chars();
    if chars.next() != Some('-') {
        return None;
    }
    if chars.next() != Some(c) {
        return None;
    }
    let rest: String = chars.collect();
    if rest.is_empty() {
        Some(None)
    } else {
        Some(Some(rest))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn t(args: &[&str]) -> Vec<String> {
        translate(args.iter().map(|s| s.to_string()).collect()).unwrap()
    }

    fn t_err(args: &[&str]) -> String {
        translate(args.iter().map(|s| s.to_string()).collect())
            .unwrap_err()
            .to_string()
    }

    #[test]
    fn plain_command() {
        assert_eq!(t(&["ls", "-la"]), vec!["--", "ls", "-la"]);
    }

    #[test]
    fn explicit_separator() {
        assert_eq!(t(&["--", "ls", "-la"]), vec!["--", "ls", "-la"]);
    }

    #[test]
    fn user_space() {
        assert_eq!(t(&["-u", "root", "id"]), vec!["-u", "root", "--", "id"]);
    }

    #[test]
    fn user_glued() {
        assert_eq!(t(&["-uroot", "id"]), vec!["-u", "root", "--", "id"]);
    }

    #[test]
    fn group_space() {
        assert_eq!(t(&["-g", "wheel", "id"]), vec!["-g", "wheel", "--", "id"]);
    }

    #[test]
    fn group_glued() {
        assert_eq!(t(&["-gwheel", "id"]), vec!["-g", "wheel", "--", "id"]);
    }

    #[test]
    fn login_shell() {
        assert_eq!(t(&["-i"]), vec!["-i"]);
    }

    #[test]
    fn shell_flag() {
        assert_eq!(t(&["-s"]), vec!["--via-shell"]);
    }

    #[test]
    fn non_interactive() {
        assert_eq!(t(&["-n", "id"]), vec!["--no-ask-password", "--", "id"]);
    }

    #[test]
    fn unknown_long_flag_passthrough() {
        assert_eq!(
            t(&["--slice=user.slice", "id"]),
            vec!["--slice=user.slice", "--", "id"]
        );
    }

    #[test]
    fn unrecognized_short_flag_errors() {
        assert!(t_err(&["-z"]).contains("unrecognized sudo flag"));
    }

    #[test]
    fn list_flag_errors() {
        assert!(t_err(&["-l"]).contains("not supported"));
    }

    #[test]
    fn no_args_opens_shell() {
        assert_eq!(t(&[]), Vec::<String>::new());
    }
}

mod check;
mod cli;
mod config;
mod outcome;
mod report;

use std::process::ExitCode;

use clap::Parser;

use crate::{cli::Cli, config::Config, outcome::Outcome};

const EXIT_LINT: u8 = 1;
const EXIT_FAIL: u8 = 2;

fn main() -> ExitCode {
	let cli = Cli::parse();

	let outcome = match gather(&cli) {
		Ok(outcome) => outcome,
		Err(e) => {
			eprintln!("{e}");
			return ExitCode::from(EXIT_FAIL);
		}
	};

	report::render(&outcome, cli.output_format, cli.quiet);

	if outcome.iter().any(Outcome::failed) {
		return ExitCode::from(EXIT_LINT);
	}

	ExitCode::SUCCESS
}

fn gather(cli: &Cli) -> hmerr::Result<Vec<Outcome>> {
	let config = Config::resolve(cli)?;

	cli.file
		.iter()
		.map(|file| check::check(file, &config))
		.collect()
}

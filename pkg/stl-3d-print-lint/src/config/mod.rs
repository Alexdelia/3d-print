mod printer;
mod rule;

pub use printer::Printer;
pub use rule::{Overhang, Rule, Sliver};

use std::{
	env, fs,
	path::{Path, PathBuf},
};

use hmerr::{ioe, pfe, ple, pwe};
use serde::Deserialize;

use crate::cli::Cli;

const NAME: &str = "stl-3d-print-lint.toml";

#[derive(Default, Deserialize)]
#[serde(default, deny_unknown_fields, rename_all = "kebab-case")]
pub struct Config {
	pub printer: Printer,
	pub rule: Rule,
}

impl Config {
	pub fn resolve(cli: &Cli) -> hmerr::Result<Self> {
		let path = match &cli.config {
			Some(path) => Some(path.clone()),
			None => discover(),
		};

		let mut config = match path {
			Some(path) => parse(&path)?,
			None => Self::default(),
		};

		if let Some(nozzle) = cli.nozzle {
			config.printer.nozzle = nozzle;
		}
		if !cli.select.is_empty() {
			config.rule.select.clone_from(&cli.select);
		}
		if !cli.ignore.is_empty() {
			config.rule.ignore.clone_from(&cli.ignore);
		}

		Ok(config)
	}
}

fn discover() -> Option<PathBuf> {
	let start = env::current_dir().ok()?;

	start
		.ancestors()
		.map(|dir| dir.join(NAME))
		.find(|candidate| candidate.is_file())
}

fn parse(path: &Path) -> hmerr::Result<Config> {
	let content = fs::read_to_string(path).map_err(|e| ioe!(path.to_string_lossy(), e))?;

	let error = match toml::from_str(&content) {
		Ok(config) => return Ok(config),
		Err(error) => error,
	};

	let line = error
		.span()
		.map(|span| (locate(&content, span.start), span.len().max(1)))
		.map(|((index, line, column), width)| ple!(line, i: index, w: pwe!((column, width))))
		.unwrap_or_default();

	pfe!(
		error.message(),
		f: path.to_string_lossy(),
		l: line,
	)?
}

fn locate(content: &str, offset: usize) -> (usize, &str, usize) {
	let before = content.get(..offset).unwrap_or(content);
	let index = before.matches('\n').count();
	let column = before
		.rsplit('\n')
		.next()
		.unwrap_or_default()
		.chars()
		.count();
	let line = content.lines().nth(index).unwrap_or_default();

	(index, line, column)
}

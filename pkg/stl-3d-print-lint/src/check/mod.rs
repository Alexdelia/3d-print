mod mesh;
mod overhang;
mod rule;
mod scan;
mod sliver;
mod topology;
mod union;

use std::path::Path;

use scan::Scan;

use crate::{config::Config, outcome::Outcome};

pub fn check(file: &Path, config: &Config) -> hmerr::Result<Outcome> {
	let scan = Scan::build(file, config)?;

	Ok(Outcome {
		file: file.to_path_buf(),
		fact: scan.fact(),
		diagnostic: rule::run(&scan, config),
	})
}

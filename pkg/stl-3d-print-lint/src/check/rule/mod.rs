mod msh;
mod sup;
mod thn;

use std::cmp::Reverse;

use crate::{check::scan::Scan, config::Config, outcome::Diagnostic};

pub fn run(scan: &Scan, config: &Config) -> Vec<Diagnostic> {
	let mut diagnostic = [
		msh::check(&scan.mesh, &scan.topology),
		sup::check(scan, &config.rule.overhang),
		thn::check(scan, &config.rule.sliver, &config.printer),
	]
	.into_iter()
	.flatten()
	.collect::<Vec<_>>();

	diagnostic.retain(|d| config.rule.enabled(d.code));
	diagnostic.sort_by_key(|d| Reverse(d.severity));

	diagnostic
}

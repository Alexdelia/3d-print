use ansi::{BOLD, DIM, GREEN, RED, RESET};
use hmerr::display::{FILE_COLOR, FILE_SIGN, HELP, HELP_SIGN, SIDE_SIGN};

use crate::outcome::{Diagnostic, Fact, Outcome, Severity};

const PAD: &str = " ";
const WRAP: &str = "\n      ";
const CUBIC_MM_PER_CUBIC_CM: f64 = 1000.0;
const NEGLIGIBLE_SPAN: f64 = 1.5;

pub fn render(outcome: &[Outcome], quiet: bool) {
	for file in outcome {
		if !quiet || file.failed() {
			head(file);
		}

		for diagnostic in &file.diagnostic {
			block(file, diagnostic);
		}
	}

	summary(outcome);
}

fn head(outcome: &Outcome) {
	let (word, color) = if outcome.failed() {
		("fail", RED)
	} else {
		("ok", GREEN)
	};

	println!(
		"\n{color}{BOLD}{word:>4}{RESET}  {BOLD}{}{RESET}\n      {}",
		outcome.file.to_string_lossy(),
		sheet(&outcome.fact)
	);
}

fn sheet(fact: &Fact) -> String {
	let [x, y, z] = fact.size();
	let state = if fact.watertight {
		"watertight"
	} else {
		"open"
	};

	format!(
		"{x:.2} x {y:.2} x {z:.2} mm   {:.2} cm3   {}   {}   {state}\n      {}",
		fact.volume / CUBIC_MM_PER_CUBIC_CM,
		plural(fact.facet, "facet", "facets"),
		plural(fact.part, "part", "parts"),
		facing(fact),
	)
}

fn facing(fact: &Fact) -> String {
	let overhang = if fact.unsupported > 0.0 {
		format!("{:.2} mm2 unsupported", fact.unsupported)
	} else {
		"no unsupported overhang".to_owned()
	};

	let ceiling = if fact.ceiling > 0 {
		format!(
			"{}, {:.2} mm widest bridge",
			plural(fact.ceiling, "ceiling", "ceilings"),
			fact.bridge
		)
	} else {
		"no ceiling".to_owned()
	};

	let speckle = if fact.speckle > 0 {
		format!(
			"   {} under {NEGLIGIBLE_SPAN} mm wide",
			plural(fact.speckle, "patch", "patches")
		)
	} else {
		String::new()
	};

	format!(
		"{overhang}   {ceiling}   {:.2} mm2 of chamfer   {:.2} mm2 on the bed{speckle}",
		fact.chamfer, fact.bed
	)
}

fn block(outcome: &Outcome, diagnostic: &Diagnostic) {
	println!(
		"\n{}: {BOLD}{}{RESET}  {}",
		diagnostic.severity.label(),
		diagnostic.code.as_str(),
		diagnostic.message
	);

	let at = match &diagnostic.at {
		Some(spot) => format!(" {spot}"),
		None => String::new(),
	};

	println!(
		"{PAD}{FILE_SIGN}{FILE_COLOR}{}{at}{RESET}",
		outcome.file.to_string_lossy()
	);

	for detail in &diagnostic.detail {
		println!("{PAD}{SIDE_SIGN}{DIM}{detail}{RESET}");
	}

	if let Some(help) = &diagnostic.help {
		println!("{PAD}{HELP_SIGN}{HELP}{}", help.replace('\n', WRAP));
	}
}

fn summary(outcome: &[Outcome]) {
	let count = |severity| {
		outcome
			.iter()
			.map(|file| file.count(severity))
			.sum::<usize>()
	};

	println!(
		"\n{} checked, {}, {}",
		plural(outcome.len(), "file", "files"),
		plural(count(Severity::Error), "error", "errors"),
		plural(count(Severity::Warning), "warning", "warnings"),
	);
}

fn plural(count: usize, one: &str, many: &str) -> String {
	let word = if count == 1 { one } else { many };

	format!("{count} {word}")
}

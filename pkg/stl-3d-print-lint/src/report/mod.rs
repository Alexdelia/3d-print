mod concise;
mod full;

use crate::{cli::Format, outcome::Outcome};

pub fn render(outcome: &[Outcome], format: Format, quiet: bool) {
	match format {
		Format::Full => full::render(outcome, quiet),
		Format::Concise => concise::render(outcome),
	}
}

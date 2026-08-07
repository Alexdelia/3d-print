mod code;
mod diagnostic;
mod fact;
mod severity;
mod spot;

pub use code::Code;
pub use diagnostic::Diagnostic;
pub use fact::Fact;
pub use severity::Severity;
pub use spot::Spot;

use std::path::PathBuf;

pub struct Outcome {
	pub file: PathBuf,
	pub fact: Fact,
	pub diagnostic: Vec<Diagnostic>,
}

impl Outcome {
	pub fn failed(&self) -> bool {
		self.count(Severity::Error) > 0
	}

	pub fn count(&self, severity: Severity) -> usize {
		self.diagnostic
			.iter()
			.filter(|d| d.severity == severity)
			.count()
	}
}

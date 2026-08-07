use super::{Code, Severity, Spot};

pub struct Diagnostic {
	pub code: Code,
	pub severity: Severity,
	pub message: String,
	pub at: Option<Spot>,
	pub detail: Vec<String>,
	pub help: Option<String>,
}

impl Diagnostic {
	pub fn new(code: Code, message: impl Into<String>) -> Self {
		Self {
			code,
			severity: code.severity(),
			message: message.into(),
			at: None,
			detail: Vec::new(),
			help: None,
		}
	}

	pub fn at(mut self, spot: Spot) -> Self {
		self.at = Some(spot);
		self
	}

	pub fn detail(mut self, detail: impl Into<String>) -> Self {
		self.detail.push(detail.into());
		self
	}

	pub fn help(mut self, help: impl Into<String>) -> Self {
		self.help = Some(help.into());
		self
	}
}

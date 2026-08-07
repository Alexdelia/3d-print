use ansi::{BOLD, RED, RESET, YELLOW};

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Severity {
	Warning,
	Error,
}

impl Severity {
	pub const fn as_str(self) -> &'static str {
		match self {
			Self::Warning => "warning",
			Self::Error => "error",
		}
	}

	pub const fn color(self) -> &'static str {
		match self {
			Self::Warning => YELLOW,
			Self::Error => RED,
		}
	}

	pub fn label(self) -> String {
		format!("{RESET}{BOLD}{}{}{RESET}", self.color(), self.as_str())
	}
}

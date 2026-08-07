use super::Severity;

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Category {
	Msh,
	Sup,
	Thn,
}

impl Category {
	pub const fn as_str(self) -> &'static str {
		match self {
			Self::Msh => "MSH",
			Self::Sup => "SUP",
			Self::Thn => "THN",
		}
	}
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Code {
	Msh001,
	Msh002,
	Msh003,
	Msh004,
	Msh005,
	Msh006,
	Msh007,
	Sup001,
	Sup002,
	Thn001,
	Thn002,
}

impl Code {
	pub const fn as_str(self) -> &'static str {
		match self {
			Self::Msh001 => "MSH001",
			Self::Msh002 => "MSH002",
			Self::Msh003 => "MSH003",
			Self::Msh004 => "MSH004",
			Self::Msh005 => "MSH005",
			Self::Msh006 => "MSH006",
			Self::Msh007 => "MSH007",
			Self::Sup001 => "SUP001",
			Self::Sup002 => "SUP002",
			Self::Thn001 => "THN001",
			Self::Thn002 => "THN002",
		}
	}

	pub const fn category(self) -> Category {
		match self {
			Self::Msh001
			| Self::Msh002
			| Self::Msh003
			| Self::Msh004
			| Self::Msh005
			| Self::Msh006
			| Self::Msh007 => Category::Msh,
			Self::Sup001 | Self::Sup002 => Category::Sup,
			Self::Thn001 | Self::Thn002 => Category::Thn,
		}
	}

	pub const fn severity(self) -> Severity {
		match self {
			Self::Msh001
			| Self::Msh002
			| Self::Msh004
			| Self::Msh006
			| Self::Sup001
			| Self::Thn001 => Severity::Error,
			Self::Msh003 | Self::Msh005 | Self::Msh007 | Self::Sup002 | Self::Thn002 => {
				Severity::Warning
			}
		}
	}

	pub fn selected_by(self, pattern: &str) -> bool {
		let pattern = pattern.trim().to_uppercase();

		pattern == "ALL" || pattern == self.as_str() || pattern == self.category().as_str()
	}
}

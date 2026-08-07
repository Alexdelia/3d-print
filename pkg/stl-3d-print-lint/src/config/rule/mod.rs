mod overhang;
mod sliver;

pub use overhang::Overhang;
pub use sliver::Sliver;

use serde::Deserialize;

use crate::outcome::Code;

const ALL: &str = "ALL";

#[derive(Deserialize)]
#[serde(default, deny_unknown_fields, rename_all = "kebab-case")]
pub struct Rule {
	pub select: Vec<String>,
	pub ignore: Vec<String>,
	pub overhang: Overhang,
	pub sliver: Sliver,
}

impl Default for Rule {
	fn default() -> Self {
		Self {
			select: vec![ALL.to_owned()],
			ignore: Vec::new(),
			overhang: Overhang::default(),
			sliver: Sliver::default(),
		}
	}
}

impl Rule {
	pub fn enabled(&self, code: Code) -> bool {
		let selected = self.select.iter().any(|pattern| code.selected_by(pattern));
		let ignored = self.ignore.iter().any(|pattern| code.selected_by(pattern));

		selected && !ignored
	}
}

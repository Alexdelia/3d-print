use serde::Deserialize;

const FEATHER: f64 = 30.0;
const THIN: f64 = 60.0;

#[derive(Deserialize)]
#[serde(default, deny_unknown_fields, rename_all = "kebab-case")]
pub struct Sliver {
	pub feather: f64,
	pub thin: f64,
}

impl Default for Sliver {
	fn default() -> Self {
		Self {
			feather: FEATHER,
			thin: THIN,
		}
	}
}

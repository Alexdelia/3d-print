use serde::Deserialize;

const SELF_SUPPORTING: f64 = 45.0;
const TOLERANCE: f64 = 0.5;
const MAX_BRIDGE: f64 = 20.0;

#[derive(Deserialize)]
#[serde(default, deny_unknown_fields, rename_all = "kebab-case")]
pub struct Overhang {
	pub self_supporting: f64,
	pub tolerance: f64,
	pub max_bridge: f64,
}

impl Default for Overhang {
	fn default() -> Self {
		Self {
			self_supporting: SELF_SUPPORTING,
			tolerance: TOLERANCE,
			max_bridge: MAX_BRIDGE,
		}
	}
}

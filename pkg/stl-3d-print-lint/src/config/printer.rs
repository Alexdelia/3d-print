use serde::Deserialize;

const NOZZLE: f64 = 0.4;
const LAYER_HEIGHT: f64 = 0.2;
const BED: [f64; 3] = [250.0, 210.0, 210.0];

#[derive(Deserialize)]
#[serde(default, deny_unknown_fields, rename_all = "kebab-case")]
pub struct Printer {
	pub nozzle: f64,
	pub layer_height: f64,
	pub bed: [f64; 3],
}

impl Default for Printer {
	fn default() -> Self {
		Self {
			nozzle: NOZZLE,
			layer_height: LAYER_HEIGHT,
			bed: BED,
		}
	}
}

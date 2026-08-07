use std::fmt::Display;

#[derive(Clone, Copy)]
pub struct Spot {
	pub x: f64,
	pub y: f64,
	pub z: f64,
}

impl Display for Spot {
	fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
		write!(f, "({:.2}, {:.2}, {:.2})", self.x, self.y, self.z)
	}
}

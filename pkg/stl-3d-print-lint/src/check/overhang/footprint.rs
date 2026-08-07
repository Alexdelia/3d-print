use super::NEGLIGIBLE_SPAN;

use crate::{check::mesh::Vector, outcome::Spot};

pub struct Footprint {
	min: [f64; 2],
	max: [f64; 2],
	pub area: f64,
}

pub struct Patch {
	pub z: f64,
	pub span: [f64; 2],
	pub area: f64,
	pub at: Spot,
}

impl Default for Footprint {
	fn default() -> Self {
		Self {
			min: [f64::INFINITY; 2],
			max: [f64::NEG_INFINITY; 2],
			area: 0.0,
		}
	}
}

impl Footprint {
	pub fn widen(&mut self, corner: [Vector; 3], area: f64) {
		for vertex in corner {
			for (slot, value) in self.min.iter_mut().zip(vertex) {
				*slot = slot.min(value);
			}
			for (slot, value) in self.max.iter_mut().zip(vertex) {
				*slot = slot.max(value);
			}
		}

		self.area += area;
	}

	pub fn patch(&self, z: f64) -> Patch {
		Patch {
			z,
			span: [self.max[0] - self.min[0], self.max[1] - self.min[1]],
			area: self.area,
			at: Spot {
				x: f64::midpoint(self.min[0], self.max[0]),
				y: f64::midpoint(self.min[1], self.max[1]),
				z,
			},
		}
	}
}

impl Patch {
	pub fn bridge(&self) -> f64 {
		self.span[0].min(self.span[1])
	}

	pub fn speckle(&self) -> bool {
		self.wide() < NEGLIGIBLE_SPAN
	}

	pub fn wide(&self) -> f64 {
		self.span[0].max(self.span[1])
	}
}

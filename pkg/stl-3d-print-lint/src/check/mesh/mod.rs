#[cfg(test)]
pub mod fixture;
mod load;

pub use load::load;

use crate::outcome::Spot;

pub type Vector = [f64; 3];

pub struct Facet {
	pub vertex: [Vector; 3],
}

pub struct Mesh {
	pub facet: Vec<Facet>,
}

impl Facet {
	pub fn normal(&self) -> Vector {
		let [a, b, c] = self.vertex;

		cross(subtract(b, a), subtract(c, a))
	}

	pub fn area(&self) -> f64 {
		length(self.normal()) / 2.0
	}

	fn sextupled_volume(&self) -> f64 {
		let [a, b, c] = self.vertex;

		dot(a, cross(b, c))
	}
}

impl Mesh {
	pub fn bound(&self) -> (Vector, Vector) {
		let mut min = [f64::INFINITY; 3];
		let mut max = [f64::NEG_INFINITY; 3];

		for facet in &self.facet {
			for vertex in facet.vertex {
				for axis in 0..3 {
					min[axis] = min[axis].min(vertex[axis]);
					max[axis] = max[axis].max(vertex[axis]);
				}
			}
		}

		(min, max)
	}

	pub fn volume(&self) -> f64 {
		self.facet.iter().map(Facet::sextupled_volume).sum::<f64>() / 6.0
	}
}

impl From<Vector> for Spot {
	fn from(vector: Vector) -> Self {
		Self {
			x: vector[0],
			y: vector[1],
			z: vector[2],
		}
	}
}

pub fn subtract(a: Vector, b: Vector) -> Vector {
	[a[0] - b[0], a[1] - b[1], a[2] - b[2]]
}

pub fn cross(a: Vector, b: Vector) -> Vector {
	[
		a[1] * b[2] - a[2] * b[1],
		a[2] * b[0] - a[0] * b[2],
		a[0] * b[1] - a[1] * b[0],
	]
}

pub fn dot(a: Vector, b: Vector) -> f64 {
	a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

pub fn length(v: Vector) -> f64 {
	dot(v, v).sqrt()
}

use super::{Facet, Mesh, Vector};

pub const SIDE: f64 = 10.0;

pub type Triangle = [Vector; 3];

pub fn mesh(triangle: &[Triangle]) -> Mesh {
	Mesh {
		facet: triangle
			.iter()
			.map(|vertex| Facet { vertex: *vertex })
			.collect(),
	}
}

pub fn cube() -> Vec<Triangle> {
	let s = SIDE;

	vec![
		[[0.0, 0.0, 0.0], [0.0, s, 0.0], [s, s, 0.0]],
		[[0.0, 0.0, 0.0], [s, s, 0.0], [s, 0.0, 0.0]],
		[[0.0, 0.0, s], [s, 0.0, s], [s, s, s]],
		[[0.0, 0.0, s], [s, s, s], [0.0, s, s]],
		[[0.0, 0.0, 0.0], [s, 0.0, 0.0], [s, 0.0, s]],
		[[0.0, 0.0, 0.0], [s, 0.0, s], [0.0, 0.0, s]],
		[[0.0, s, 0.0], [0.0, s, s], [s, s, s]],
		[[0.0, s, 0.0], [s, s, s], [s, s, 0.0]],
		[[0.0, 0.0, 0.0], [0.0, 0.0, s], [0.0, s, s]],
		[[0.0, 0.0, 0.0], [0.0, s, s], [0.0, s, 0.0]],
		[[s, 0.0, 0.0], [s, s, 0.0], [s, s, s]],
		[[s, 0.0, 0.0], [s, s, s], [s, 0.0, s]],
	]
}

pub fn flipped(triangle: &[Triangle]) -> Vec<Triangle> {
	triangle.iter().map(|[a, b, c]| [*a, *c, *b]).collect()
}

pub fn moved(triangle: &[Triangle], by: Vector) -> Vec<Triangle> {
	triangle
		.iter()
		.map(|corner| corner.map(|v| [v[0] + by[0], v[1] + by[1], v[2] + by[2]]))
		.collect()
}

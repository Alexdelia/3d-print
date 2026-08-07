mod weld;

use std::collections::HashMap;

use weld::Weld;

use crate::{
	check::{
		mesh::{Facet, Mesh, Vector},
		union::Union,
	},
	outcome::Spot,
};

const DEGENERATE_AREA: f64 = 1e-9;
const CORNER: usize = 3;

pub type Edge = (usize, usize);

pub struct Face {
	pub corner: [usize; CORNER],
}

pub struct Side {
	pub face: usize,
	pub forward: bool,
}

pub struct Topology {
	pub vertex: Vec<Vector>,
	pub face: Vec<Face>,
	pub edge: HashMap<Edge, Vec<Side>>,
	pub degenerate: Vec<usize>,
	pub part: usize,
}

impl Topology {
	pub fn build(mesh: &Mesh) -> Self {
		let mut weld = Weld::with_capacity(mesh.facet.len() * CORNER);
		let mut face = Vec::with_capacity(mesh.facet.len());
		let mut degenerate = Vec::new();

		for (facet, shape) in mesh.facet.iter().enumerate() {
			if shape.area() < DEGENERATE_AREA {
				degenerate.push(facet);
				continue;
			}

			face.push(Face {
				corner: corner_of(shape, &mut weld),
			});
		}

		let edge = wire(&face);
		let part = split(&face, &edge);

		Self {
			vertex: weld.vertex,
			face,
			edge,
			degenerate,
			part,
		}
	}

	pub fn facet(&self, face: &Face) -> Option<Facet> {
		let [a, b, c] = face.corner;

		Some(Facet {
			vertex: [
				self.vertex.get(a).copied()?,
				self.vertex.get(b).copied()?,
				self.vertex.get(c).copied()?,
			],
		})
	}

	pub fn floor(&self) -> f64 {
		self.vertex
			.iter()
			.map(|vertex| vertex[2])
			.fold(f64::INFINITY, f64::min)
	}

	pub fn watertight(&self) -> bool {
		self.edge.values().all(|side| side.len() == 2)
	}

	pub fn midpoint(&self, edge: Edge) -> Spot {
		let start = self.vertex.get(edge.0).copied().unwrap_or_default();
		let end = self.vertex.get(edge.1).copied().unwrap_or_default();

		Spot {
			x: f64::midpoint(start[0], end[0]),
			y: f64::midpoint(start[1], end[1]),
			z: f64::midpoint(start[2], end[2]),
		}
	}
}

fn corner_of(shape: &Facet, weld: &mut Weld) -> [usize; CORNER] {
	let [a, b, c] = shape.vertex;

	[weld.index(a), weld.index(b), weld.index(c)]
}

fn wire(face: &[Face]) -> HashMap<Edge, Vec<Side>> {
	let mut edge: HashMap<Edge, Vec<Side>> = HashMap::with_capacity(face.len() * CORNER);

	for (index, shape) in face.iter().enumerate() {
		for step in 0..CORNER {
			let from = shape.corner[step];
			let to = shape.corner[(step + 1) % CORNER];
			let forward = from < to;
			let key = if forward { (from, to) } else { (to, from) };

			edge.entry(key).or_default().push(Side {
				face: index,
				forward,
			});
		}
	}

	edge
}

fn split(face: &[Face], edge: &HashMap<Edge, Vec<Side>>) -> usize {
	let mut union = Union::new(face.len());

	for side in edge.values() {
		let Some(first) = side.first() else {
			continue;
		};

		for other in side.iter().skip(1) {
			union.join(first.face, other.face);
		}
	}

	union.count()
}

#[cfg(test)]
mod test {
	use super::Topology;

	use crate::check::mesh::fixture::{SIDE, cube, mesh, moved};

	const CORNER_OF_A_CUBE: usize = 8;

	#[test]
	fn a_cube_is_one_watertight_part() {
		let topology = Topology::build(&mesh(&cube()));

		assert!(topology.watertight());
		assert_eq!(topology.part, 1);
		assert_eq!(topology.vertex.len(), CORNER_OF_A_CUBE);
		assert!(topology.degenerate.is_empty());
	}

	#[test]
	fn a_cube_missing_a_facet_is_open() {
		let mut triangle = cube();
		triangle.pop();

		assert!(!Topology::build(&mesh(&triangle)).watertight());
	}

	#[test]
	fn two_cubes_apart_are_two_parts() {
		let mut triangle = cube();
		triangle.extend(moved(&cube(), [SIDE * 2.0, 0.0, 0.0]));

		let topology = Topology::build(&mesh(&triangle));

		assert!(topology.watertight());
		assert_eq!(topology.part, 2);
	}
}

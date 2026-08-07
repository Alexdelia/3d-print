mod cluster;
mod footprint;

pub use footprint::Patch;

use std::collections::HashMap;

use footprint::Footprint;

use crate::{
	check::{
		mesh::{Facet, length},
		topology::Topology,
	},
	config::Overhang as Setting,
};

const FLAT: f64 = 1.0;
const DOWNWARD: f64 = 1e-6;
const AREA_FLOOR: f64 = 1e-9;
const LAYER_GRID: f64 = 100.0;
const NEGLIGIBLE_SPAN: f64 = 1.5;

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
enum Facing {
	Ceiling,
	Unsupported,
}

pub struct Overhang {
	pub ceiling: Vec<Patch>,
	pub unsupported: Vec<Patch>,
	pub chamfer: f64,
	pub bed: f64,
	pub speckle: usize,
}

impl Overhang {
	pub fn build(topology: &Topology, setting: &Setting) -> Self {
		let floor = quantize(topology.floor());

		let mut bucket: HashMap<(Facing, i64), Vec<usize>> = HashMap::new();
		let mut chamfer = 0.0;
		let mut bed = 0.0;

		for (index, face) in topology.face.iter().enumerate() {
			let Some(facet) = topology.facet(face) else {
				continue;
			};

			let Some(slope) = slope(&facet) else {
				continue;
			};

			let area = facet.area();
			if area < AREA_FLOOR {
				continue;
			}

			if slope >= setting.self_supporting - setting.tolerance {
				if slope < setting.self_supporting + setting.tolerance {
					chamfer += area;
				}
				continue;
			}

			let layer = layer(&facet);
			let facing = if slope < FLAT {
				Facing::Ceiling
			} else {
				Facing::Unsupported
			};

			if facing == Facing::Ceiling && layer == floor {
				bed += area;
				continue;
			}

			bucket.entry((facing, layer)).or_default().push(index);
		}

		let ceiling = patch(topology, &bucket, Facing::Ceiling);
		let unsupported = patch(topology, &bucket, Facing::Unsupported);
		let speckle = ceiling
			.iter()
			.chain(&unsupported)
			.filter(|p| p.speckle())
			.count();

		Self {
			ceiling: ceiling.into_iter().filter(|p| !p.speckle()).collect(),
			unsupported: unsupported.into_iter().filter(|p| !p.speckle()).collect(),
			chamfer,
			bed,
			speckle,
		}
	}

	pub fn unsupported_area(&self) -> f64 {
		self.unsupported.iter().map(|patch| patch.area).sum()
	}

	pub fn widest_bridge(&self) -> f64 {
		self.ceiling.iter().map(Patch::bridge).fold(0.0, f64::max)
	}
}

fn slope(facet: &Facet) -> Option<f64> {
	let normal = facet.normal();
	let scale = length(normal);

	if scale <= 0.0 {
		return None;
	}

	let down = -normal[2] / scale;

	if down <= DOWNWARD {
		return None;
	}

	Some(down.min(1.0).acos().to_degrees())
}

fn layer(facet: &Facet) -> i64 {
	quantize(
		facet
			.vertex
			.iter()
			.map(|vertex| vertex[2])
			.fold(f64::INFINITY, f64::min),
	)
}

#[expect(
	clippy::cast_possible_truncation,
	reason = "printer scale coordinates cannot leave i64"
)]
fn quantize(z: f64) -> i64 {
	(z * LAYER_GRID).round() as i64
}

#[expect(
	clippy::cast_precision_loss,
	reason = "printer scale coordinates cannot leave f64 precision"
)]
fn height(layer: i64) -> f64 {
	layer as f64 / LAYER_GRID
}

fn patch(
	topology: &Topology,
	bucket: &HashMap<(Facing, i64), Vec<usize>>,
	wanted: Facing,
) -> Vec<Patch> {
	let mut found: Vec<Patch> = bucket
		.iter()
		.filter(|((facing, _), _)| *facing == wanted)
		.flat_map(|((_, layer), face)| {
			cluster::split(topology, face)
				.into_iter()
				.map(|group| footprint(topology, &group).patch(height(*layer)))
		})
		.collect();

	found.sort_by(|a, b| b.area.total_cmp(&a.area));

	found
}

fn footprint(topology: &Topology, face: &[usize]) -> Footprint {
	let mut footprint = Footprint::default();

	for index in face {
		let Some(facet) = topology.face.get(*index).and_then(|f| topology.facet(f)) else {
			continue;
		};

		footprint.widen(facet.vertex, facet.area());
	}

	footprint
}

#[cfg(test)]
mod test {
	use super::Overhang;

	use crate::{
		check::{
			mesh::fixture::{SIDE, Triangle, mesh},
			topology::Topology,
		},
		config::Overhang as Setting,
	};

	const BELOW: f64 = -SIDE * 2.0;

	fn bed() -> Triangle {
		[[0.0, 0.0, BELOW], [0.0, SIDE, BELOW], [SIDE, SIDE, BELOW]]
	}

	fn ramp(slope: f64) -> Triangle {
		let turn = |x: f64, z: f64| {
			[
				x * slope.to_radians().cos() + z * slope.to_radians().sin(),
				0.0,
				-x * slope.to_radians().sin() + z * slope.to_radians().cos(),
			]
		};

		let flat: Triangle = [[0.0, 0.0, 0.0], [0.0, SIDE, 0.0], [SIDE, SIDE, 0.0]];

		flat.map(|v| {
			let [x, _, z] = turn(v[0], v[2]);
			[x, v[1], z]
		})
	}

	fn built(slope: f64) -> Overhang {
		Overhang::build(
			&Topology::build(&mesh(&[bed(), ramp(slope)])),
			&Setting::default(),
		)
	}

	#[test]
	fn a_flat_underside_off_the_bed_is_a_ceiling() {
		let overhang = built(0.0);

		assert_eq!(overhang.ceiling.len(), 1);
		assert!(overhang.unsupported.is_empty());
		assert!(overhang.bed > 0.0);
	}

	#[test]
	fn a_shallow_underside_needs_support() {
		let overhang = built(30.0);

		assert_eq!(overhang.unsupported.len(), 1);
		assert!(overhang.ceiling.is_empty());
	}

	#[test]
	fn a_45_degree_chamfer_carries_itself() {
		let overhang = built(45.0);

		assert!(overhang.unsupported.is_empty());
		assert!(overhang.chamfer > 0.0);
	}

	#[test]
	fn a_steep_wall_is_not_an_overhang() {
		let overhang = built(60.0);

		assert!(overhang.unsupported.is_empty());
		assert!(overhang.ceiling.is_empty());
		assert!(overhang.chamfer <= 0.0);
	}
}

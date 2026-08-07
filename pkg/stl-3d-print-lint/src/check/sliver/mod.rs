use crate::{
	check::{
		mesh::{Vector, cross, dot, length, subtract},
		topology::{Edge, Face, Topology},
	},
	config::Sliver as Setting,
	outcome::Spot,
};

const NEGLIGIBLE_LENGTH: f64 = 0.2;
const STRAIGHT: f64 = 180.0;

pub struct Wedge {
	pub angle: f64,
	pub span: f64,
	pub at: Spot,
}

pub struct Sliver {
	pub feather: Vec<Wedge>,
	pub thin: Vec<Wedge>,
}

impl Sliver {
	pub fn build(topology: &Topology, setting: &Setting) -> Self {
		let mut feather = Vec::new();
		let mut thin = Vec::new();

		for (edge, side) in &topology.edge {
			let [first, second] = side.as_slice() else {
				continue;
			};

			let Some(angle) = interior(topology, *edge, first.face, second.face) else {
				continue;
			};

			if angle >= setting.thin {
				continue;
			}

			let span = span(topology, *edge);
			if span < NEGLIGIBLE_LENGTH {
				continue;
			}

			let wedge = Wedge {
				angle,
				span,
				at: topology.midpoint(*edge),
			};

			if angle < setting.feather {
				feather.push(wedge);
			} else {
				thin.push(wedge);
			}
		}

		feather.sort_by(|a, b| a.angle.total_cmp(&b.angle));
		thin.sort_by(|a, b| a.angle.total_cmp(&b.angle));

		Self { feather, thin }
	}
}

impl Wedge {
	pub fn reach(&self, nozzle: f64) -> f64 {
		let half = (self.angle.to_radians() / 2.0).sin();

		if half <= 0.0 {
			return f64::INFINITY;
		}

		nozzle / (2.0 * half)
	}
}

pub fn total(wedge: &[Wedge]) -> f64 {
	wedge.iter().map(|w| w.span).sum()
}

fn interior(topology: &Topology, edge: Edge, first: usize, second: usize) -> Option<f64> {
	let first = topology.face.get(first)?;
	let second = topology.face.get(second)?;

	let one = unit(normal(topology, first)?);
	let other = unit(normal(topology, second)?);

	let between = dot(one, other).clamp(-1.0, 1.0).acos().to_degrees();

	let on_edge = topology.vertex.get(edge.0).copied()?;
	let across = topology.vertex.get(opposite(second, edge)?).copied()?;

	if dot(subtract(across, on_edge), one) < 0.0 {
		Some(STRAIGHT - between)
	} else {
		Some(STRAIGHT + between)
	}
}

fn normal(topology: &Topology, face: &Face) -> Option<Vector> {
	let [a, b, c] = face.corner;
	let a = topology.vertex.get(a).copied()?;
	let b = topology.vertex.get(b).copied()?;
	let c = topology.vertex.get(c).copied()?;

	Some(cross(subtract(b, a), subtract(c, a)))
}

fn opposite(face: &Face, edge: Edge) -> Option<usize> {
	face.corner
		.iter()
		.find(|corner| **corner != edge.0 && **corner != edge.1)
		.copied()
}

fn unit(v: Vector) -> Vector {
	let scale = length(v);

	if scale <= 0.0 {
		return v;
	}

	[v[0] / scale, v[1] / scale, v[2] / scale]
}

fn span(topology: &Topology, edge: Edge) -> f64 {
	let start = topology.vertex.get(edge.0).copied().unwrap_or_default();
	let end = topology.vertex.get(edge.1).copied().unwrap_or_default();

	length(subtract(end, start))
}

#[cfg(test)]
mod test {
	use super::Sliver;

	use crate::{
		check::{
			mesh::fixture::{SIDE, Triangle, mesh},
			topology::Topology,
		},
		config::Sliver as Setting,
	};

	fn wedge(angle: f64) -> Vec<Triangle> {
		let far = [
			SIDE * angle.to_radians().cos(),
			0.0,
			SIDE * angle.to_radians().sin(),
		];

		vec![
			[[0.0, 0.0, 0.0], [0.0, SIDE, 0.0], [SIDE, 0.0, 0.0]],
			[[0.0, SIDE, 0.0], [0.0, 0.0, 0.0], far],
		]
	}

	fn built(angle: f64) -> Sliver {
		Sliver::build(&Topology::build(&mesh(&wedge(angle))), &Setting::default())
	}

	#[test]
	fn a_very_sharp_wedge_feathers() {
		let sliver = built(20.0);

		assert_eq!(sliver.feather.len(), 1);
		assert!(sliver.thin.is_empty());
	}

	#[test]
	fn a_moderately_sharp_wedge_is_thin() {
		let sliver = built(45.0);

		assert!(sliver.feather.is_empty());
		assert_eq!(sliver.thin.len(), 1);
	}

	#[test]
	fn a_right_angle_is_neither() {
		let sliver = built(90.0);

		assert!(sliver.feather.is_empty());
		assert!(sliver.thin.is_empty());
	}

	#[test]
	fn a_feather_tip_is_under_one_bead_for_longer_than_a_blunt_one() {
		let sharp = built(20.0);
		let blunt = built(45.0);

		let sharp = sharp.feather.first().map(|w| w.reach(0.4)).unwrap();
		let blunt = blunt.thin.first().map(|w| w.reach(0.4)).unwrap();

		assert!(sharp > blunt);
	}
}

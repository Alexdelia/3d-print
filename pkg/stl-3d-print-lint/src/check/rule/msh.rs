use std::collections::HashMap;

use crate::{
	check::{
		mesh::{Mesh, length, subtract},
		topology::{Edge, Topology},
	},
	outcome::{Code, Diagnostic, Spot},
};

const WORST: usize = 8;
const SOLID: f64 = 0.0;

pub fn check(mesh: &Mesh, topology: &Topology) -> Vec<Diagnostic> {
	[
		open(topology),
		pinch(topology),
		degenerate(mesh, topology),
		winding(topology),
		part(topology),
		inverted(mesh, topology),
		duplicate(topology),
	]
	.into_iter()
	.flatten()
	.collect()
}

fn open(topology: &Topology) -> Option<Diagnostic> {
	let found = gather(topology, |side| side == 1);

	if found.is_empty() {
		return None;
	}

	Some(
		listed(
			Diagnostic::new(
				Code::Msh001,
				format!("{} open edges, the mesh is not watertight", found.len()),
			),
			topology,
			&found,
		)
		.help(
			"an edge bounding a single facet is a hole\n\
			 a slicer will guess how to close it, and the guess is rarely the modelled shape",
		),
	)
}

fn pinch(topology: &Topology) -> Option<Diagnostic> {
	let found = gather(topology, |side| side > 2);

	if found.is_empty() {
		return None;
	}

	Some(
		listed(
			Diagnostic::new(
				Code::Msh002,
				format!("{} edges where more than two facets meet", found.len()),
			),
			topology,
			&found,
		)
		.help(
			"the surface touches itself along these edges, so inside and outside are not decided\n\
			 usually two solids sharing an edge exactly, separate them or overlap them properly",
		),
	)
}

fn degenerate(mesh: &Mesh, topology: &Topology) -> Option<Diagnostic> {
	let first = topology.degenerate.first()?;
	let spot = mesh
		.facet
		.get(*first)
		.map(|facet| Spot::from(facet.vertex[0]))?;

	Some(
		Diagnostic::new(
			Code::Msh003,
			format!("{} facets with no area", topology.degenerate.len()),
		)
		.at(spot)
		.help(
			"zero area facets carry no surface and every slicer drops them\n\
			 they are normal output of a csg boolean, but they hide the topology they sit in",
		),
	)
}

fn winding(topology: &Topology) -> Option<Diagnostic> {
	let found: Vec<Edge> = topology
		.edge
		.iter()
		.filter(|(_, side)| {
			side.len() == 2 && side.first().map(|s| s.forward) == side.last().map(|s| s.forward)
		})
		.map(|(edge, _)| *edge)
		.collect();

	if found.is_empty() {
		return None;
	}

	Some(
		listed(
			Diagnostic::new(
				Code::Msh004,
				format!(
					"{} edges where two facets disagree on which way is out",
					found.len()
				),
			),
			topology,
			&found,
		)
		.help("neighbouring facets wound the same way share every edge in opposite directions"),
	)
}

fn part(topology: &Topology) -> Option<Diagnostic> {
	if topology.part < 2 {
		return None;
	}

	Some(
		Diagnostic::new(
			Code::Msh005,
			format!("{} disconnected parts in one file", topology.part),
		)
		.help(
			"deliberate for a plate of several pieces, a mistake for a single part\n\
			 a stray shell that shares no edge with the body prints as loose plastic",
		),
	)
}

fn inverted(mesh: &Mesh, topology: &Topology) -> Option<Diagnostic> {
	if !topology.watertight() || mesh.volume() >= SOLID {
		return None;
	}

	Some(
		Diagnostic::new(
			Code::Msh006,
			format!(
				"solid encloses {:.2} mm3, the normals point inward",
				mesh.volume()
			),
		)
		.help("the whole surface is wound the wrong way, so the slicer sees a hole, not a part"),
	)
}

fn duplicate(topology: &Topology) -> Option<Diagnostic> {
	let mut seen: HashMap<[usize; 3], usize> = HashMap::with_capacity(topology.face.len());

	for face in &topology.face {
		let mut corner = face.corner;
		corner.sort_unstable();
		*seen.entry(corner).or_default() += 1;
	}

	let found = seen.values().filter(|count| **count > 1).count();

	if found == 0 {
		return None;
	}

	Some(
		Diagnostic::new(Code::Msh007, format!("{found} facets modelled twice")).help(
			"two facets on the same three vertices, so the surface is doubled there\n\
			 harmless to slice, but it means two solids share a face instead of overlapping",
		),
	)
}

fn gather(topology: &Topology, wanted: impl Fn(usize) -> bool) -> Vec<Edge> {
	topology
		.edge
		.iter()
		.filter(|(_, side)| wanted(side.len()))
		.map(|(edge, _)| *edge)
		.collect()
}

fn listed(diagnostic: Diagnostic, topology: &Topology, found: &[Edge]) -> Diagnostic {
	let mut worst: Vec<(f64, Edge)> = found
		.iter()
		.map(|edge| (span(topology, *edge), *edge))
		.collect();

	worst.sort_by(|a, b| b.0.total_cmp(&a.0));

	let mut diagnostic = match worst.first() {
		Some((_, edge)) => diagnostic.at(topology.midpoint(*edge)),
		None => diagnostic,
	};

	for (span, edge) in worst.iter().take(WORST) {
		diagnostic = diagnostic.detail(format!("{span:6.2} mm at {}", topology.midpoint(*edge)));
	}

	if worst.len() > WORST {
		diagnostic = diagnostic.detail(format!("... {} more", worst.len() - WORST));
	}

	diagnostic
}

fn span(topology: &Topology, edge: Edge) -> f64 {
	let start = topology.vertex.get(edge.0).copied().unwrap_or_default();
	let end = topology.vertex.get(edge.1).copied().unwrap_or_default();

	length(subtract(end, start))
}

#[cfg(test)]
mod test {
	use super::check;

	use crate::{
		check::{
			mesh::{
				Mesh,
				fixture::{SIDE, Triangle, cube, flipped, mesh, moved},
			},
			topology::Topology,
		},
		outcome::Code,
	};

	fn code(shape: &Mesh) -> Vec<Code> {
		check(shape, &Topology::build(shape))
			.iter()
			.map(|d| d.code)
			.collect()
	}

	fn of(triangle: &[Triangle]) -> Vec<Code> {
		code(&mesh(triangle))
	}

	#[test]
	fn a_cube_is_clean() {
		assert!(of(&cube()).is_empty());
	}

	#[test]
	fn a_missing_facet_is_a_hole() {
		let mut triangle = cube();
		triangle.pop();

		assert_eq!(of(&triangle), vec![Code::Msh001]);
	}

	#[test]
	fn a_repeated_facet_pinches_and_doubles() {
		let mut triangle = cube();
		let Some(first) = triangle.first().copied() else {
			return;
		};
		triangle.push(first);

		let found = of(&triangle);

		assert!(found.contains(&Code::Msh002));
		assert!(found.contains(&Code::Msh007));
	}

	#[test]
	fn a_flat_facet_has_no_area() {
		let mut triangle = cube();
		triangle.push([[0.0, 0.0, 0.0], [SIDE, 0.0, 0.0], [SIDE, 0.0, 0.0]]);

		assert_eq!(of(&triangle), vec![Code::Msh003]);
	}

	#[test]
	fn one_flipped_facet_disagrees_with_its_neighbours() {
		let mut triangle = cube();
		let Some(first) = triangle.first_mut() else {
			return;
		};
		*first = [first[0], first[2], first[1]];

		assert!(of(&triangle).contains(&Code::Msh004));
	}

	#[test]
	fn two_cubes_are_two_parts() {
		let mut triangle = cube();
		triangle.extend(moved(&cube(), [SIDE * 2.0, 0.0, 0.0]));

		assert_eq!(of(&triangle), vec![Code::Msh005]);
	}

	#[test]
	fn a_cube_wound_inside_out_encloses_nothing() {
		assert_eq!(of(&flipped(&cube())), vec![Code::Msh006]);
	}
}

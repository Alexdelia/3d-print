use std::collections::{HashMap, hash_map::Entry};

use crate::check::{topology::Topology, union::Union};

pub fn split(topology: &Topology, face: &[usize]) -> Vec<Vec<usize>> {
	let mut union = Union::new(face.len());
	let mut seen: HashMap<usize, usize> = HashMap::new();

	for (slot, index) in face.iter().enumerate() {
		let Some(shape) = topology.face.get(*index) else {
			continue;
		};

		for corner in shape.corner {
			match seen.entry(corner) {
				Entry::Occupied(first) => union.join(*first.get(), slot),
				Entry::Vacant(empty) => {
					empty.insert(slot);
				}
			}
		}
	}

	let mut group: HashMap<usize, Vec<usize>> = HashMap::new();

	for (slot, index) in face.iter().enumerate() {
		group.entry(union.root(slot)).or_default().push(*index);
	}

	group.into_values().collect()
}

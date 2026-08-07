use std::collections::HashMap;

use crate::check::mesh::Vector;

const WELD: f64 = 1e-4;
const OFFSET: [i64; 3] = [0, -1, 1];

type Cell = [i64; 3];

pub struct Weld {
	cell: HashMap<Cell, usize>,
	pub vertex: Vec<Vector>,
}

impl Weld {
	pub fn with_capacity(capacity: usize) -> Self {
		Self {
			cell: HashMap::with_capacity(capacity),
			vertex: Vec::with_capacity(capacity),
		}
	}

	pub fn index(&mut self, vertex: Vector) -> usize {
		let cell = cell_of(vertex);

		if let Some(&index) = around(cell).find_map(|near| self.cell.get(&near)) {
			return index;
		}

		let index = self.vertex.len();
		self.cell.insert(cell, index);
		self.vertex.push(vertex);

		index
	}
}

#[expect(
	clippy::cast_possible_truncation,
	reason = "printer scale coordinates cannot leave i64"
)]
fn cell_of(vertex: Vector) -> Cell {
	[
		(vertex[0] / WELD).round() as i64,
		(vertex[1] / WELD).round() as i64,
		(vertex[2] / WELD).round() as i64,
	]
}

fn around(cell: Cell) -> impl Iterator<Item = Cell> {
	OFFSET.into_iter().flat_map(move |dx| {
		OFFSET.into_iter().flat_map(move |dy| {
			OFFSET
				.into_iter()
				.map(move |dz| [cell[0] + dx, cell[1] + dy, cell[2] + dz])
		})
	})
}

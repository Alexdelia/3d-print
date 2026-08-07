pub struct Fact {
	pub min: [f64; 3],
	pub max: [f64; 3],
	pub facet: usize,
	pub part: usize,
	pub volume: f64,
	pub watertight: bool,
	pub ceiling: usize,
	pub bridge: f64,
	pub unsupported: f64,
	pub chamfer: f64,
	pub bed: f64,
	pub speckle: usize,
}

impl Fact {
	pub fn size(&self) -> [f64; 3] {
		[
			self.max[0] - self.min[0],
			self.max[1] - self.min[1],
			self.max[2] - self.min[2],
		]
	}
}

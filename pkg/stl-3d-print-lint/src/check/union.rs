pub struct Union {
	parent: Vec<usize>,
}

impl Union {
	pub fn new(size: usize) -> Self {
		Self {
			parent: (0..size).collect(),
		}
	}

	pub fn join(&mut self, a: usize, b: usize) {
		let a = self.root(a);
		let b = self.root(b);

		if a != b
			&& let Some(slot) = self.parent.get_mut(b)
		{
			*slot = a;
		}
	}

	pub fn count(&mut self) -> usize {
		let mut count = 0;

		for index in 0..self.parent.len() {
			if self.root(index) == index {
				count += 1;
			}
		}

		count
	}

	pub fn root(&mut self, mut index: usize) -> usize {
		while let Some(&up) = self.parent.get(index) {
			if up == index {
				break;
			}

			if let Some(&grand) = self.parent.get(up)
				&& let Some(slot) = self.parent.get_mut(index)
			{
				*slot = grand;
			}

			index = up;
		}

		index
	}
}

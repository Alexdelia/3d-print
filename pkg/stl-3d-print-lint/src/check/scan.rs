use std::path::Path;

use hmerr::ge;

use crate::{
	check::{
		mesh::{self, Mesh},
		overhang::Overhang,
		sliver::Sliver,
		topology::Topology,
	},
	config::Config,
	outcome::Fact,
};

pub struct Scan {
	pub mesh: Mesh,
	pub topology: Topology,
	pub overhang: Overhang,
	pub sliver: Sliver,
}

impl Scan {
	pub fn build(file: &Path, config: &Config) -> hmerr::Result<Self> {
		let mesh = mesh::load(file)?;

		if mesh.facet.is_empty() {
			Err(ge!(
				format!("{} holds no facet", file.to_string_lossy()),
				h: "an empty mesh means the export produced nothing, check the scad that made it",
			))?;
		}

		let topology = Topology::build(&mesh);
		let overhang = Overhang::build(&topology, &config.rule.overhang);
		let sliver = Sliver::build(&topology, &config.rule.sliver);

		Ok(Self {
			mesh,
			topology,
			overhang,
			sliver,
		})
	}

	pub fn fact(&self) -> Fact {
		let (min, max) = self.mesh.bound();

		Fact {
			min,
			max,
			facet: self.mesh.facet.len(),
			part: self.topology.part,
			volume: self.mesh.volume(),
			watertight: self.topology.watertight(),
			ceiling: self.overhang.ceiling.len(),
			bridge: self.overhang.widest_bridge(),
			unsupported: self.overhang.unsupported_area(),
			chamfer: self.overhang.chamfer,
			bed: self.overhang.bed,
			speckle: self.overhang.speckle,
		}
	}
}

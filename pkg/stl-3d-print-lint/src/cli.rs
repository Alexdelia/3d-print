use std::path::PathBuf;

use clap::{Parser, ValueEnum};

#[derive(Parser)]
#[command(version, about = "lint stl meshes for 3d printing readiness")]
pub struct Cli {
	#[arg(required = true, value_name = "STL")]
	pub file: Vec<PathBuf>,

	#[arg(short, long, value_name = "TOML")]
	pub config: Option<PathBuf>,

	#[arg(long, value_delimiter = ',', value_name = "CODE")]
	pub select: Vec<String>,

	#[arg(long, value_delimiter = ',', value_name = "CODE")]
	pub ignore: Vec<String>,

	#[arg(long, value_name = "MM")]
	pub nozzle: Option<f64>,

	#[arg(long, value_enum, default_value_t = Format::Full)]
	pub output_format: Format,

	#[arg(short, long)]
	pub quiet: bool,
}

#[derive(Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum Format {
	Full,
	Concise,
}

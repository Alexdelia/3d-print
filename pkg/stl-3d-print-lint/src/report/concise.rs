use crate::outcome::Outcome;

pub fn render(outcome: &[Outcome]) {
	for file in outcome {
		for diagnostic in &file.diagnostic {
			let at = match &diagnostic.at {
				Some(spot) => format!("{spot}:"),
				None => String::new(),
			};

			println!(
				"{}:{at} {} {}",
				file.file.to_string_lossy(),
				diagnostic.code.as_str(),
				diagnostic.message
			);
		}
	}
}

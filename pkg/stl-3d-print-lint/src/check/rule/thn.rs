use crate::{
	check::{
		scan::Scan,
		sliver::{Wedge, total},
	},
	config::{Printer, Sliver as Setting},
	outcome::{Code, Diagnostic},
};

const WORST: usize = 8;

pub fn check(scan: &Scan, setting: &Setting, printer: &Printer) -> Vec<Diagnostic> {
	[
		feather(scan, setting, printer),
		thin(scan, setting, printer),
	]
	.into_iter()
	.flatten()
	.collect()
}

fn feather(scan: &Scan, setting: &Setting, printer: &Printer) -> Option<Diagnostic> {
	let found = &scan.sliver.feather;

	Some(
		listed(
			edge(
				Code::Thn001,
				found,
				&format!("under {:.0} deg", setting.feather),
			)?,
			found,
			printer.nozzle,
		)
		.help(format!(
			"the two surfaces close at too sharp an angle to hold {:.1} mm of material\n\
			 the tip prints as nothing, a gap, or a whisker, whatever the slicer feels like",
			printer.nozzle,
		)),
	)
}

fn thin(scan: &Scan, setting: &Setting, printer: &Printer) -> Option<Diagnostic> {
	let found = &scan.sliver.thin;

	Some(
		listed(
			edge(
				Code::Thn002,
				found,
				&format!("between {:.0} and {:.0} deg", setting.feather, setting.thin),
			)?,
			found,
			printer.nozzle,
		)
		.help("thin enough that the tip is one bead wide, so it will look soft, not sharp"),
	)
}

fn edge(code: Code, found: &[Wedge], range: &str) -> Option<Diagnostic> {
	let at = found.first().map(|wedge| wedge.at)?;

	Some(Diagnostic::new(code, format!("{:.2} mm of edge {range}", total(found))).at(at))
}

fn listed(diagnostic: Diagnostic, found: &[Wedge], nozzle: f64) -> Diagnostic {
	let mut diagnostic = diagnostic;

	for wedge in found.iter().take(WORST) {
		diagnostic = diagnostic.detail(format!(
			"{:5.1} deg over {:6.2} mm at {}, under one bead for {:.2} mm",
			wedge.angle,
			wedge.span,
			wedge.at,
			wedge.reach(nozzle),
		));
	}

	if found.len() > WORST {
		diagnostic = diagnostic.detail(format!("... {} more", found.len() - WORST));
	}

	diagnostic
}

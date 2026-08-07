use crate::{
	check::{overhang::Patch, scan::Scan},
	config::Overhang as Setting,
	outcome::{Code, Diagnostic},
};

const WORST: usize = 8;
const NEGLIGIBLE_SPAN: f64 = 1.5;

pub fn check(scan: &Scan, setting: &Setting) -> Vec<Diagnostic> {
	[unsupported(scan, setting), bridge(scan, setting)]
		.into_iter()
		.flatten()
		.collect()
}

fn unsupported(scan: &Scan, setting: &Setting) -> Option<Diagnostic> {
	let found = &scan.overhang.unsupported;

	if found.is_empty() {
		return None;
	}

	let at = found.first().map(|patch| patch.at)?;

	Some(
		listed(
			Diagnostic::new(
				Code::Sup001,
				format!(
					"{:.2} mm2 of downward surface shallower than {:.0} deg",
					scan.overhang.unsupported_area(),
					setting.self_supporting,
				),
			)
			.at(at),
			found,
		)
		.help(format!(
			"these faces need support, or the part needs a chamfer of at least {:.0} deg\n\
			 a slicer set to auto support will decide for you, and it will decide badly",
			setting.self_supporting,
		)),
	)
}

fn bridge(scan: &Scan, setting: &Setting) -> Option<Diagnostic> {
	let found: Vec<&Patch> = scan
		.overhang
		.ceiling
		.iter()
		.filter(|patch| patch.bridge() > setting.max_bridge)
		.collect();

	let at = found.first().map(|patch| patch.at)?;

	Some(
		Diagnostic::new(
			Code::Sup002,
			format!(
				"{} horizontal ceiling wider than the {:.1} mm bridge budget",
				found.len(),
				setting.max_bridge,
			),
		)
		.at(at)
		.help(
			"a flat ceiling prints as a bridge, and a long one sags into whatever is under it\n\
			 split it, arch it, or accept the sag and say so",
		),
	)
}

fn listed(diagnostic: Diagnostic, found: &[Patch]) -> Diagnostic {
	let mut diagnostic = diagnostic;

	for patch in found.iter().take(WORST) {
		if patch.wide() < NEGLIGIBLE_SPAN {
			continue;
		}

		diagnostic = diagnostic.detail(format!(
			"{:8.2} mm2 at z={:<7.2} spanning {:.2} x {:.2} mm",
			patch.area, patch.z, patch.span[0], patch.span[1],
		));
	}

	if found.len() > WORST {
		diagnostic = diagnostic.detail(format!("... {} more", found.len() - WORST));
	}

	diagnostic
}

use std::{fs, path::Path};

use hmerr::{ge, ioe, pfe, ple};

use super::{Facet, Mesh, Vector};

const HEADER: usize = 80;
const COUNT: usize = 4;
const RECORD: usize = 50;
const SCALAR: usize = 4;
const CORNER: usize = 3;
const NORMAL: usize = 3;
const TEXT_MARK: &[u8] = b"solid";

pub fn load(path: &Path) -> hmerr::Result<Mesh> {
	let raw = fs::read(path).map_err(|e| ioe!(path.to_string_lossy(), e))?;

	decode(&raw, path)
}

fn decode(raw: &[u8], path: &Path) -> hmerr::Result<Mesh> {
	if binary_sized(raw) {
		return binary(raw, path);
	}

	if raw.trim_ascii_start().starts_with(TEXT_MARK) {
		return ascii(raw, path);
	}

	Err(ge!(
		format!("{} is not a stl", path.to_string_lossy()),
		h: "a text stl starts with `solid`\n\
			a binary stl is an 80 byte header, a 4 byte facet count, then 50 bytes per facet, and this one is not that long",
	))?
}

fn declared(raw: &[u8]) -> Option<usize> {
	let bytes: [u8; COUNT] = raw.get(HEADER..HEADER + COUNT)?.try_into().ok()?;

	usize::try_from(u32::from_le_bytes(bytes)).ok()
}

fn binary_sized(raw: &[u8]) -> bool {
	declared(raw).is_some_and(|count| raw.len() == HEADER + COUNT + count * RECORD)
}

fn binary(raw: &[u8], path: &Path) -> hmerr::Result<Mesh> {
	let body = raw.get(HEADER + COUNT..).unwrap_or_default();

	let Some(facet) = body.chunks_exact(RECORD).map(record).collect() else {
		return Err(ge!(
			format!("{} is a truncated binary stl", path.to_string_lossy()),
			h: "a binary stl is an 80 byte header, a 4 byte facet count, then 50 bytes per facet",
		))?;
	};

	Ok(Mesh { facet })
}

fn record(chunk: &[u8]) -> Option<Facet> {
	let mut scalar = [0.0; CORNER * 3];

	for (slot, bytes) in scalar
		.iter_mut()
		.zip(chunk.chunks_exact(SCALAR).skip(NORMAL))
	{
		let bytes: [u8; SCALAR] = bytes.try_into().ok()?;
		*slot = f64::from(f32::from_le_bytes(bytes));
	}

	Some(Facet {
		vertex: [
			[scalar[0], scalar[1], scalar[2]],
			[scalar[3], scalar[4], scalar[5]],
			[scalar[6], scalar[7], scalar[8]],
		],
	})
}

fn ascii(raw: &[u8], path: &Path) -> hmerr::Result<Mesh> {
	let text = match str::from_utf8(raw) {
		Ok(text) => text,
		Err(e) => {
			return Err(ge!(
				format!("{} is neither a binary nor a text stl", path.to_string_lossy()),
				h: "the declared facet count does not match the file size, and the bytes are not utf8",
				s: e,
			))?;
		}
	};

	let mut facet = Vec::new();
	let mut corner: Vec<Vector> = Vec::with_capacity(CORNER);

	for (index, line) in text.lines().enumerate() {
		let mut word = line.split_whitespace();

		match word.next() {
			Some("facet") => corner.clear(),
			Some("vertex") => corner.push(triple(&mut word, line, index, path)?),
			Some("endfacet") => {
				let [a, b, c] = corner.as_slice() else {
					Err(ge!(
						format!("facet with {} vertices at line {index}", corner.len()),
						h: "every facet of a text stl holds exactly 3 vertex lines",
					))?
				};
				facet.push(Facet {
					vertex: [*a, *b, *c],
				});
			}
			_ => {}
		}
	}

	Ok(Mesh { facet })
}

fn triple<'a>(
	word: &mut impl Iterator<Item = &'a str>,
	line: &str,
	index: usize,
	path: &Path,
) -> hmerr::Result<Vector> {
	let mut vector = [0.0; 3];

	for slot in &mut vector {
		let Some(scalar) = word.next().and_then(|w| w.parse::<f64>().ok()) else {
			return pfe!(
				"expected 3 numbers",
				f: path.to_string_lossy(),
				l: ple!(line, i: index),
			)?;
		};
		*slot = scalar;
	}

	Ok(vector)
}

#[cfg(test)]
mod test {
	use super::{COUNT, HEADER, RECORD, Vector, decode};

	use std::path::Path;

	const TEXT: &str = "solid one
facet normal 0 0 -1
  outer loop
    vertex 0 0 0
    vertex 0 1 0
    vertex 1 1 0
  endloop
endfacet
endsolid one
";

	const CLOSE: f64 = 1e-9;

	fn path() -> &'static Path {
		Path::new("fixture.stl")
	}

	fn near(got: Vector, want: Vector) -> bool {
		got.iter()
			.zip(want)
			.all(|(got, want)| (got - want).abs() < CLOSE)
	}

	fn one_binary_facet() -> Vec<u8> {
		let mut raw = vec![0u8; HEADER];
		raw.extend_from_slice(&1u32.to_le_bytes());

		let scalar: [f32; 12] = [0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0];
		for value in scalar {
			raw.extend_from_slice(&value.to_le_bytes());
		}
		raw.extend_from_slice(&0u16.to_le_bytes());

		raw
	}

	#[test]
	fn binary_and_text_agree() {
		let raw = one_binary_facet();
		assert_eq!(raw.len(), HEADER + COUNT + RECORD);

		let binary = decode(&raw, path()).unwrap();
		let text = decode(TEXT.as_bytes(), path()).unwrap();

		assert_eq!(binary.facet.len(), 1);
		assert_eq!(text.facet.len(), 1);
		assert_eq!(binary.facet[0].vertex, text.facet[0].vertex);
		assert!(near(binary.facet[0].vertex[2], [1.0, 1.0, 0.0]));
	}

	#[test]
	fn text_starting_like_a_binary_header_is_read_as_text() {
		let padded = format!("{TEXT}{}", " ".repeat(HEADER));

		assert_eq!(decode(padded.as_bytes(), path()).unwrap().facet.len(), 1);
	}

	#[test]
	fn truncated_binary_is_rejected() {
		let mut raw = one_binary_facet();
		raw.extend_from_slice(&[0u8; 4]);

		assert!(decode(&raw, path()).is_err());
	}
}

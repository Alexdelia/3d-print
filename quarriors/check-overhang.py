#!/usr/bin/env python3

import math
import struct
import sys
from collections import defaultdict
from collections.abc import Iterator
from pathlib import Path

SELF_SUPPORTING = 45.0
TOLERANCE = 0.5
NEGLIGIBLE_SPAN = 1.5

BUCKET_ORDER = ("horizontal", "unsupported", "45 deg chamfer", "steeper than 45")
CEILING_BUCKETS = ("horizontal", "unsupported")

type Vector = tuple[float, float, float]
type Triangle = tuple[Vector, Vector, Vector]
type Footprint = list[float]


def facets(path: Path) -> Iterator[tuple[Vector, Triangle]]:
	with path.open("rb") as f:
		f.read(80)
		count = struct.unpack("<I", f.read(4))[0]
		for _ in range(count):
			values = struct.unpack("<12fH", f.read(50))
			yield values[0:3], (values[3:6], values[6:9], values[9:12])


def triangle_area(a: Vector, b: Vector, c: Vector) -> float:
	u = [b[i] - a[i] for i in range(3)]
	v = [c[i] - a[i] for i in range(3)]
	cross = [
		u[1] * v[2] - u[2] * v[1],
		u[2] * v[0] - u[0] * v[2],
		u[0] * v[1] - u[1] * v[0],
	]
	return 0.5 * math.sqrt(sum(x * x for x in cross))


def slope_of(normal: Vector) -> float | None:
	length = math.sqrt(sum(x * x for x in normal)) or 1.0
	down = -normal[2] / length
	return math.degrees(math.acos(min(1.0, down))) if down > 1e-6 else None


def bucket_of(slope: float) -> str:
	if slope < 1.0:
		return "horizontal"
	if slope < SELF_SUPPORTING - TOLERANCE:
		return "unsupported"
	if slope < SELF_SUPPORTING + TOLERANCE:
		return "45 deg chamfer"
	return "steeper than 45"


def new_footprint() -> Footprint:
	return [1e9, -1e9, 1e9, -1e9, 0.0]


def widen(footprint: Footprint, vertices: Triangle, area: float) -> None:
	for v in vertices:
		footprint[0] = min(footprint[0], v[0])
		footprint[1] = max(footprint[1], v[0])
		footprint[2] = min(footprint[2], v[1])
		footprint[3] = max(footprint[3], v[1])
	footprint[4] += area


def measure(path: Path) -> tuple[dict[str, float], dict[float, Footprint]]:
	areas: dict[str, float] = defaultdict(float)
	ceilings: dict[float, Footprint] = defaultdict(new_footprint)

	for normal, vertices in facets(path):
		slope = slope_of(normal)
		if slope is None:
			continue

		area = triangle_area(*vertices)
		if area < 1e-9:
			continue

		bucket = bucket_of(slope)
		areas[bucket] += area

		if bucket in CEILING_BUCKETS:
			floor = round(min(v[2] for v in vertices), 2)
			widen(ceilings[floor], vertices, area)

	return areas, ceilings


def print_areas(areas: dict[str, float]) -> None:
	for bucket in BUCKET_ORDER:
		area = areas.get(bucket, 0.0)
		if area:
			print(f"  {bucket:<18}{area:9.2f} mm2")


def print_ceilings(ceilings: dict[float, Footprint]) -> None:
	engraving = 0.0

	for z, (x0, x1, y0, y1, area) in sorted(ceilings.items()):
		if min(x1 - x0, y1 - y0) < NEGLIGIBLE_SPAN:
			engraving += area
			continue
		print(
			f"  ceiling at z={z:<7.2f}{area:8.2f} mm2"
			f"  spans {x1 - x0:.2f} x {y1 - y0:.2f} mm"
		)

	if engraving:
		print(
			f"  engraving         {engraving:9.2f} mm2"
			f"  in patches under {NEGLIGIBLE_SPAN} mm"
		)


def report(path: Path) -> None:
	areas, ceilings = measure(path)

	print(path)
	print_areas(areas)
	print_ceilings(ceilings)
	print()


if __name__ == "__main__":
	for path in sys.argv[1:]:
		report(Path(path))

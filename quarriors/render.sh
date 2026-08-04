#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
mkdir -p render

rotation=66.20,0.00,313.60
imgsize=800,800
colorscheme=Tomorrow
background='#f8f8f8'
padding=12

render() {
	openscad \
		--camera="0,0,0,$rotation,0" \
		--viewall \
		--autocenter \
		--projection=ortho \
		--imgsize="$imgsize" \
		--colorscheme="$colorscheme" \
		-o "render/$1.png" \
		"${@:2}"

	magick "render/$1.png" \
		-alpha set \
		-fuzz 2% -fill none -floodfill +0+0 "$background" \
		-trim +repage \
		-bordercolor none -border "$padding" \
		"render/$1.png"
}

render layout scad/layout.scad

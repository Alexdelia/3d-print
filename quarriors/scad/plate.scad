include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

plate_gap = 8;

base_card_stacks = [for (n = base_card_counts) stack_of(n)];
expansion_card_stacks = [for (n = expansion_card_counts) stack_of(n)];
tray_sizes = [5, 6, 2];

function row_offset(index) = index * (tray_width + plate_gap);

for (i = [0 : len(tray_sizes) - 1])
    color("Coral")
        translate([0, row_offset(i), 0])
            dice_tray(tray_sizes[i]);

trays_depth = row_offset(len(tray_sizes));

color("SteelBlue")
    translate([0, trays_depth, 0])
        card_well(98);

cards_depth = trays_depth + card_well_width() + plate_gap;

color("MediumSeaGreen")
    translate([0, cards_depth, 0])
        card_block(base_card_stacks);

color("Goldenrod")
    translate([card_block_depth(base_card_stacks) + plate_gap, cards_depth, 0])
        card_block(expansion_card_stacks);

echo(str("tray 5 footprint     ", tray_length(5), " x ", tray_width, " x ", tray_height));
echo(str("tray 6 footprint     ", tray_length(6), " x ", tray_width, " x ", tray_height));
echo(str("tray 2 footprint     ", tray_length(2), " x ", tray_width, " x ", tray_height));
echo(str("card well footprint  ", card_well_length(), " x ", card_well_width(), " x ", well_height_for(98)));
echo(str("base cards footprint ", card_block_depth(base_card_stacks), " x ", card_block_width(),
         " x ", card_block_height()));
echo(str("expansions footprint ", card_block_depth(expansion_card_stacks), " x ", card_block_width(),
         " x ", card_block_height()));
echo(str("both card blocks     ",
         card_block_depth(base_card_stacks) + card_block_depth(expansion_card_stacks),
         " x ", card_block_width()));
echo(str("plate extent         ", card_well_length(), " x ",
         cards_depth + card_block_width()));

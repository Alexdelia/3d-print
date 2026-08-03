include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

plate_gap = 8;

base_card_stacks = [3, 20, 30] * card_thickness;
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

color("MediumSeaGreen")
    translate([0, trays_depth + card_well_width() + plate_gap, 0])
        card_block(base_card_stacks);

echo(str("tray 5 footprint     ", tray_length(5), " x ", tray_width, " x ", tray_height));
echo(str("tray 6 footprint     ", tray_length(6), " x ", tray_width, " x ", tray_height));
echo(str("tray 2 footprint     ", tray_length(2), " x ", tray_width, " x ", tray_height));
echo(str("card well footprint  ", card_well_length(), " x ", card_well_width(), " x ", well_height_for(98)));
echo(str("card block footprint ", card_block_depth(base_card_stacks), " x ", card_block_width(),
         " x ", floor_thickness + card_block_wall_height));
echo(str("plate extent         ", card_well_length(), " x ",
         trays_depth + card_well_width() + plate_gap + card_block_width()));

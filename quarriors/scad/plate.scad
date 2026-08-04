include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

plate_gap = 8;

tray_sizes = [5, 6, 2];

function row_offset(index) =
    index * (tray_width + plate_gap);

for(i = [0:len(tray_sizes) - 1])
    translate([0, row_offset(i), 0])
        dice_tray(tray_sizes[i]);

trays_depth = row_offset(len(tray_sizes));

translate([0, trays_depth, 0])
    card_block(all_card_stacks);

split_depth = trays_depth + card_block_width() + plate_gap;

translate([0, split_depth, 0])
    card_block(base_card_stacks, part_color = "SteelBlue");

translate([card_block_depth(base_card_stacks) + plate_gap, split_depth, 0])
    card_block(expansion_card_stacks, part_color = "Goldenrod");

echo(str("tray 5 footprint     ", tray_length(5), " x ", tray_width, " x ", tray_height));
echo(str("tray 6 footprint     ", tray_length(6), " x ", tray_width, " x ", tray_height));
echo(str("tray 2 footprint     ", tray_length(2), " x ", tray_width, " x ", tray_height));
echo(str("merged cards         ", card_block_depth(all_card_stacks), " x ", card_block_width(), " x ", card_block_height()));
echo(str("base cards           ", card_block_depth(base_card_stacks), " x ", card_block_width()));
echo(str("expansion cards      ", card_block_depth(expansion_card_stacks), " x ", card_block_width()));
echo(str("split penalty        ", card_block_depth(base_card_stacks) + card_block_depth(expansion_card_stacks) - card_block_depth(all_card_stacks), " mm of extra depth"));
echo(str("cards reach up to    ", card_reach()));
echo(str("plate extent         ", max(tray_length(6), card_block_depth(all_card_stacks), card_block_depth(base_card_stacks) + plate_gap + card_block_depth(expansion_card_stacks)), " x ", split_depth + card_block_width()));

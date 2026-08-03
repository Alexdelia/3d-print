include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

part = -1;
plate_gap = 6;

tray_copies = 1;
base_card_stacks = [for (n = base_card_counts) stack_of(n)];

module test_part(index) {
    if (index == 0)
        dice_tray(5);
    else if (index == 1)
        dice_tray(6);
    else
        card_block(base_card_stacks);
}

module plate() {
    for (i = [0 : tray_copies - 1])
        translate([0, i * (tray_width + plate_gap), 0]) test_part(0);

    translate([0, tray_copies * (tray_width + plate_gap), 0]) test_part(1);

    translate([tray_length(6) + 2 * plate_gap, 0, 0]) test_part(2);
}

if (part < 0) plate(); else test_part(part);

plate_x = tray_length(6) + 2 * plate_gap + card_block_depth(base_card_stacks);
plate_y = max((tray_copies + 1) * (tray_width + plate_gap) - plate_gap, card_block_width());

echo(str("skirt mode            ", skirt_mode, ", skirt ", skirt_height,
         ", rests on ", skirt_mode == "rim" ? "rim below" : "dice below"));
echo(str("tray part height      ", tray_height));
echo(str("stack pitch           ", tray_pitch));
echo(str("rim gap in stack      ", rim_gap));
echo(str("skirt grip on flat    ", skirt_flat_engagement));
echo(str("die side play         ", die_side_play, " per side"));
echo(str("row slack, 5 real dice", channel_length(5) - 5 * die_measured));
echo(str("skirt cavity play     ", skirt_cavity_play, " per side, ",
         skirt_cavity_play + skirt_lead_in, " at the mouth"));
echo(str("first layer wall      ", first_layer_wall));
echo(str("bridge span / height  ", tray_width - 2 * wall, " / ", skirt_height));

echo(str("part 0  5-die tray x", tray_copies, "  ", tray_length(5), " x ", tray_width,
         " x ", tray_height, "  channel ", channel_length(5), "  pocket ", pocket_width));
echo(str("part 1  6-die tray    ", tray_length(6), " x ", tray_width,
         " x ", tray_height, "  channel ", channel_length(6), "  pocket ", pocket_width));
echo(str("part 2  base cards    ", card_block_depth(base_card_stacks),
         " x ", card_block_width(), " x ", card_block_height(),
         "  notch ", card_notch_width, " x ", card_notch_depth));

for (i = [0 : len(base_card_counts) - 1])
    echo(str("        compartment ", i, "  ", base_card_counts[i], " cards, stack ",
             base_card_stacks[i], ", slot ", base_card_stacks[i] + card_slot_clearance));

echo(str("loaded stack of ", tray_copies + 1, "     rim ",
         tray_copies * tray_pitch + tray_height, ", dice top ",
         tray_copies * tray_pitch + skirt_height + floor_thickness + die_measured));
echo(str("plate                 ", plate_x, " x ", plate_y));

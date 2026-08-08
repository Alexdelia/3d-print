include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

part = -1;
plate_gap = 6;

tray_copies = 1;
card_stacks = all_card_stacks;

tray_5_basis = die_measured;
tray_6_basis = die_worst_case;

tray_5_width = tray_width_for(tray_5_basis);
tray_6_width = tray_width_for(tray_6_basis);

module test_part(index) {
    if (index == 0)
        dice_tray(5, basis = tray_5_basis, filled = 0);
    else if (index == 1)
        dice_tray(6, basis = tray_6_basis, filled = 0);
    else
        print_oriented(card_stacks)
            card_block(card_stacks, loaded = false);
}

module plate() {
    for(i = [0:tray_copies - 1])
        translate([0, i * (tray_5_width + plate_gap), 0])
            test_part(0);

    translate([0, tray_copies * (tray_5_width + plate_gap), 0])
        test_part(1);

    translate([tray_length(6, tray_6_basis) + 2 * plate_gap, 0, 0])
        test_part(2);
}

if (part < 0)
    plate();
else
    test_part(part);

plate_x = tray_length(6, tray_6_basis) + 2 * plate_gap + card_block_depth(card_stacks);
plate_y = max(tray_copies * (tray_5_width + plate_gap) + tray_6_width, card_block_width());

echo(str("skirt mode            ", skirt_mode, ", skirt ", skirt_height, ", rests on ", skirt_mode == "rim" ? "rim below" : "dice below"));
echo(str("tray part height      ", tray_height));
echo(str("stack pitch           ", tray_pitch));
echo(str("rim gap in stack      ", rim_gap));
echo(str("skirt grip on flat    ", skirt_flat_engagement));
echo(str("skirt cavity play     ", skirt_cavity_play, " per side, ", skirt_cavity_play + skirt_lead_in, " at the mouth"));
echo(str("first layer wall      ", first_layer_wall));

echo(str("part 0  5-die tray x", tray_copies, "  basis ", tray_5_basis, "  ", tray_length(5, tray_5_basis), " x ", tray_5_width, " x ", tray_height, "  channel ", channel_length(5, tray_5_basis), "  pocket ", pocket_width_for(tray_5_basis), "  side play ", (pocket_width_for(tray_5_basis) - die_measured) / 2, "  row slack ", channel_length(5, tray_5_basis) - 5 * die_measured, "  bridge ", tray_5_width - 2 * wall));
echo(str("part 1  6-die tray    basis ", tray_6_basis, "  ", tray_length(6, tray_6_basis), " x ", tray_6_width, " x ", tray_height, "  channel ", channel_length(6, tray_6_basis), "  pocket ", pocket_width_for(tray_6_basis), "  side play ", (pocket_width_for(tray_6_basis) - die_measured) / 2, "  row slack ", channel_length(6, tray_6_basis) - 6 * die_measured, "  bridge ", tray_6_width - 2 * wall));
echo(str("part 2  card block    ", card_block_depth(card_stacks), " x ", card_block_width(), " x ", card_block_height(), "  notch ", card_notch_width, " wide, apex at ", card_notch_apex, ", card exposed ", card_block_height() - card_notch_apex));

for(i = [0:len(card_stacks) - 1])
    echo(str("        compartment ", i, "  ", stack_count(card_stacks[i]), " cards (", stack_summary(card_stacks[i]), "), stack ", stack_depth(card_stacks[i]), ", slot ", stack_depth(card_stacks[i]) + card_slot_clearance));

echo(str("        honeycomb     ", len(honeycomb_centres()), " cells per wall, insertion ", card_insertion, ", dividers ", card_honeycomb_dividers ? "cut" : "solid", ", window ", 2 * card_honeycomb_half_width, " x ", card_honeycomb_height));
echo(str("        cell          ", card_honeycomb_cell_width, " x ", card_honeycomb_cell_height, ", tips ", card_honeycomb_tip_angle, " deg, rib ", card_honeycomb_rib, ", bridge facing the card edge ", card_honeycomb_leading_edge_bridge));

echo(str("loaded stack of ", tray_copies + 1, "     rim ", tray_copies * tray_pitch + tray_height, ", dice top ", tray_copies * tray_pitch + skirt_height + floor_thickness + die_measured));
echo(str("plate                 ", plate_x, " x ", plate_y));

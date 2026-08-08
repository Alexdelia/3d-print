include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

plate = "all";
tray_gap = 6;
preview_gap = 20;

card_stacks = all_card_stacks;

tray_5_basis = die_measured;
tray_6_basis = die_worst_case;

tray_plan = [
    [5, tray_5_basis],
    [6, tray_6_basis],
];

assert(tray_gap < 2 * (brim_gap + brim_width), "tray gap wider than two brim rings: the trays would land on separate cards");

function tray_dice(index) =
    tray_plan[index][0];
function tray_basis(index) =
    tray_plan[index][1];
function tray_size(index) =
    [tray_length(tray_dice(index), tray_basis(index)), tray_width_for(tray_basis(index))];
function tray_y(index) =
    index == 0 ? 0 : sum([
        for (i = [0:index - 1])
            tray_size(i)[1] + tray_gap
    ]);
function tray_centre(index) =
    [tray_size(index)[0] / 2, tray_y(index) + tray_size(index)[1] / 2];

function trays_plan() =
    [
        for (i = [0:len(tray_plan) - 1])
            [tray_centre(i), tray_size(i)]
    ];

function trays_plate_size() =
    [max([
        for (i = [0:len(tray_plan) - 1])
            tray_size(i)[0]
    ]) + 2 * (brim_gap + brim_width), tray_y(len(tray_plan)) - tray_gap + 2 * (brim_gap + brim_width),];

module trays_plate() {
    for(i = [0:len(tray_plan) - 1])
        translate([0, tray_y(i), 0])
            dice_tray(tray_dice(i), basis = tray_basis(i), filled = 0);

    color(tray_color)
        tray_card(trays_plan());
}

module cards_plate() {
    print_oriented(card_stacks)
        card_block(card_stacks, loaded = false);
}

if (plate == "trays")
    trays_plate();
else if (plate == "cards")
    cards_plate();
else {
    trays_plate();

    translate([0, trays_plate_size()[1] + preview_gap, 0])
        cards_plate();
}

echo(str("skirt mode            ", skirt_mode, ", skirt ", skirt_height, ", rests on ", skirt_mode == "rim" ? "rim below" : "dice below"));
echo(str("tray part height      ", tray_height));
echo(str("stack pitch           ", tray_pitch));
echo(str("rim gap in stack      ", rim_gap));
echo(str("skirt grip on flat    ", skirt_flat_engagement));
echo(str("skirt cavity play     ", skirt_cavity_play, " per side, ", skirt_cavity_play + skirt_lead_in, " at the mouth"));
echo(str("first layer wall      ", first_layer_wall, " after a ", tray_bottom_chamfer, " bottom chamfer"));
echo(str("floor chamfers        ", atan(floor_chamfer_rise), " deg from horizontal"));

for(i = [0:len(tray_plan) - 1])
    echo(str("tray ", tray_dice(i), "  basis ", tray_basis(i), "  ", tray_size(i)[0], " x ", tray_size(i)[1], " x ", tray_height, "  channel ", channel_length(tray_dice(i), tray_basis(i)), "  pocket ", pocket_width_for(tray_basis(i)), "  side play ", (pocket_width_for(tray_basis(i)) - die_measured) / 2, "  row slack ", channel_length(tray_dice(i), tray_basis(i)) - tray_dice(i) * die_measured, "  bridge ", tray_size(i)[1] - 2 * wall));

echo(str("trays plate           ", trays_plate_size()[0], " x ", trays_plate_size()[1], ", card ", brim_width, " wide x ", brim_height, " thick, tabs ", brim_tab, " across a ", brim_gap, " gap"));

echo(str("card block            ", card_block_depth(card_stacks), " x ", card_block_width(), " x ", card_block_height(), "  notch ", card_notch_width, " wide, apex at ", card_notch_apex, ", card exposed ", card_block_height() - card_notch_apex));

for(i = [0:len(card_stacks) - 1])
    echo(str("        compartment ", i, "  ", stack_count(card_stacks[i]), " cards (", stack_summary(card_stacks[i]), "), stack ", stack_depth(card_stacks[i]), ", slot ", stack_depth(card_stacks[i]) + card_slot_clearance));

echo(str("        honeycomb     ", len(honeycomb_centres()), " cells per wall, insertion ", card_insertion, ", dividers ", card_honeycomb_dividers ? "cut" : "solid", ", window ", 2 * card_honeycomb_half_width, " x ", card_honeycomb_height));
echo(str("        cell          ", card_honeycomb_cell_width, " x ", card_honeycomb_cell_height, ", tips ", card_honeycomb_tip_angle, " deg, rib ", card_honeycomb_rib, ", bridge facing the card edge ", card_honeycomb_leading_edge_bridge));

echo(str("loaded stack of 2     rim ", tray_pitch + tray_height, ", dice top ", tray_pitch + skirt_height + floor_thickness + die_measured));

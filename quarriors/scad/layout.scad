include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

scope = "all";

card_counts = [["base", 53], ["base_rotd", 72], ["all", 98]];

tray_demand = [
    ["base",      [[16, 5], [8, 6], [1, 2]]],
    ["base_rotd", [[20, 5], [8, 6], [1, 2]]],
    ["all",       [[28, 5], [8, 6], [1, 2]]],
];

function lookup(table, key) = table[search([key], table)[0]][1];

cards_in_scope = lookup(card_counts, scope);
groups_in_scope = lookup(tray_demand, scope);
trays_needed = sum([for (g = groups_in_scope) g[0]]);

well_height = well_height_for(cards_in_scope);

beside_well = [envelope, envelope - card_well_width(), envelope];
above_well = [card_well_length(), card_well_width(), envelope - well_height];
end_of_well = [card_well_width(), envelope - card_well_length(), envelope];

slots_beside = slots_in(beside_well, 6);
slots_above = slots_in(above_well, 6);
slots_end = slots_in(end_of_well, 4);

echo(str("scope                ", scope));
echo(str("trays needed         ", trays_needed));
echo(str("tray height / pitch  ", tray_height));
echo(str("lane pitch           ", lane_pitch));
echo(str("5-tray length        ", tray_length(5)));
echo(str("6-tray length        ", tray_length(6)));
echo(str("well footprint       ", card_well_length(), " x ", card_well_width()));
echo(str("well height          ", well_height));
echo(str("slots beside well    ", slots_beside));
echo(str("slots above well     ", slots_above));
echo(str("slots at well end    ", slots_end, " (4-dice only)"));
echo(str("usable slots         ", slots_beside + slots_above));
echo(str("shortfall            ", trays_needed - (slots_beside + slots_above)));

module fill_region(origin, region, dice_count) {
    lanes = lanes_in(region[1]);
    levels = levels_in(region[2]);

    if (tray_length(dice_count) <= region[0] && lanes > 0 && levels > 0)
        translate(origin)
            for (lane = [0 : lanes - 1], level = [0 : levels - 1])
                translate([0, lane * lane_pitch, level * tray_height])
                    dice_tray(dice_count);
}

module tin() {
    inset = tin_safety_margin / 2;
    %translate([-inset, -inset, 0])
        cuboid([tin_inner, tin_inner, tin_inner],
               rounding = tin_corner_radius, edges = "Z", anchor = [-1, -1, -1]);
}

tin();

color("SteelBlue") card_well(cards_in_scope);

color("Coral") fill_region([0, card_well_width(), 0], beside_well, 6);
color("MediumSeaGreen") fill_region([0, 0, well_height], above_well, 6);
color("Goldenrod") fill_region([card_well_length(), 0, 0], end_of_well, 4);

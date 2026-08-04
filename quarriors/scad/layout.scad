include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

scope = "all";
card_layout = "corner";
l_arm = 1;
cards_depth_override = 0;

tray_family = [6, 5, 4, 2];

tray_demand = [
    [
        "base",
        [
            [16, 5],
            [8, 6],
            [1, 2]
        ]
    ],
    [
        "base_rotd",
        [
            [20, 5],
            [8, 6],
            [1, 2]
        ]
    ],
    [
        "base_quarm",
        [
            [24, 5],
            [8, 6],
            [1, 2]
        ]
    ],
    [
        "all",
        [
            [28, 5],
            [8, 6],
            [1, 2]
        ]
    ],
];

function lookup(table, key) =
    table[search([key], table)[0]][1];

groups_in_scope = lookup(tray_demand, scope);
trays_needed = sum([
    for (g = groups_in_scope)
        g[0]
]);
long_trays_needed = sum([
    for (g = groups_in_scope)
        g[1] > 5 ? g[0] : 0
]);

arm_a_stacks = [
    for (i = [0:l_arm - 1])
        all_card_stacks[i]
];
arm_b_stacks = [
    for (i = [l_arm:len(all_card_stacks) - 1])
        all_card_stacks[i]
];

cards_width = card_block_width();
merged_depth = card_block_depth(all_card_stacks);
arm_a_depth = card_block_depth(arm_a_stacks);
arm_b_depth = card_block_depth(arm_b_stacks);

l_valid = card_layout != "L" || arm_a_depth + cards_width <= envelope;

cards_depth = cards_depth_override > 0 ? cards_depth_override : merged_depth;

corner_regions = [
    [cards_width, envelope - cards_depth, envelope],
    [envelope, envelope - cards_width, envelope],
];

l_regions = [
    [envelope - arm_a_depth, cards_width - arm_b_depth, envelope],
    [envelope, envelope - cards_width, envelope],
    [arm_b_depth, envelope - arm_a_depth - cards_width, envelope],
];

regions = card_layout == "L" ? l_regions : corner_regions;

function best_tray(region) =
    let (fits = [
        for (n = tray_family)
            if (tray_length(n) <= region[0])
                n
    ])
        len(fits) == 0 ? 0 : fits[0];

function region_slots(region) =
    best_tray(region) == 0 ? 0 : lanes_in(region[1]) * levels_in(region[2]);

region_trays = [
    for (r = regions)
        best_tray(r)
];
region_counts = [
    for (r = regions)
        region_slots(r)
];

long_slots = sum([
    for (i = [0:len(regions) - 1])
        region_trays[i] >= 6 ? region_counts[i] : 0
]);
short_slots = sum([
    for (i = [0:len(regions) - 1])
        region_trays[i] == 5 ? region_counts[i] : 0
]);
stub_slots = sum([
    for (i = [0:len(regions) - 1])
        region_trays[i] > 0 && region_trays[i] < 5 ? region_counts[i] : 0
]);

usable_slots = long_slots + short_slots;
long_trays_fit = long_slots >= long_trays_needed;
fits = l_valid && long_trays_fit && usable_slots >= trays_needed;

module cards() {
    if (card_layout == "L") {
        translate([cards_width, 0, 0])
            rotate([0, 0, 90])
                card_block(arm_a_stacks);

        translate([0, arm_a_depth, 0])
            card_block(arm_b_stacks, part_color = "Goldenrod");
    } else
        card_block(all_card_stacks);
}

module fill_region(origin, region, dice_count, turn = false, part_color = tray_color) {
    lanes = lanes_in(region[1]);
    levels = levels_in(region[2]);

    if (dice_count > 0 && lanes > 0 && levels > 0)
        translate(origin)
            rotate([0, 0, turn ? 90 : 0])
                for(lane = [0:lanes - 1], level = [0:levels - 1])
                    translate([0, lane * lane_pitch, level * tray_pitch])
                        dice_tray(dice_count, part_color = part_color);
}

module tin() {
    inset = tin_safety_margin / 2;
    %translate([-inset, -inset, 0])
        cuboid([tin_inner, tin_inner, tin_inner], rounding = tin_corner_radius, edges = "Z", anchor = [-1, -1, -1]);
}

tin();
cards();

if (card_layout == "L") {
    fill_region([cards_width, arm_a_depth, 0], l_regions[0], region_trays[0], turn = true);

    fill_region([envelope, 0, 0], l_regions[1], region_trays[1], turn = true, part_color = "SteelBlue");
} else {
    fill_region([envelope, 0, 0], corner_regions[0], region_trays[0], turn = true);

    fill_region([0, cards_width, 0], corner_regions[1], region_trays[1], part_color = "SteelBlue");
}

echo(str("scope                 ", scope, ", card layout ", card_layout, card_layout == "L" ? str(", arm split after ", l_arm) : ""));
echo(str("trays needed          ", trays_needed, ", of which 6-die ", long_trays_needed));
echo(str("cards reach up to     ", card_reach(), " of ", envelope, " -> ", levels_in(envelope - card_reach()), " tray levels fit above them"));
echo(str("lane pitch            ", lane_pitch, ", levels per column ", levels_in(envelope)));
echo(str("tray lengths          ", [
    for (n = tray_family)
        tray_length(n)
]));

if (card_layout == "L")
    echo(str("card arms             ", cards_width, " x ", arm_a_depth, " and ", arm_b_depth, " x ", cards_width, l_valid ? "" : "  ARM A TOO DEEP, L IMPOSSIBLE"));
else
    echo(str("card block            ", merged_depth, " x ", cards_width));

for(i = [0:len(regions) - 1])
    echo(str("region ", i, "  ", regions[i][0], " long x ", regions[i][1], " wide  -> ", region_trays[i] == 0 ? "no tray fits" : str(lanes_in(regions[i][1]), " lanes of ", region_trays[i], "-die = ", region_counts[i], " slots")));

echo(str("6-die capable slots   ", long_slots, " (need ", long_trays_needed, ")"));
echo(str("5-die only slots      ", short_slots));
echo(str("stub only slots       ", stub_slots));
echo(str("usable slots          ", usable_slots));
echo(str("verdict               ", !l_valid ? "IMPOSSIBLE" : !long_trays_fit ? str("too few 6-die slots: ", long_slots, " < ", long_trays_needed) : fits ? str("FITS, ", usable_slots - trays_needed, " spare") : str("short ", trays_needed - usable_slots)));

show_dice = true;
show_cards = true;

die_measured = 13.5;
die_worst_case = 14.0;
die_fit_clearance = 1.0;
die_corner_radius = 2.0;
die_smoothness = 96;
die_color = "WhiteSmoke";

die_icon = true;
die_faces = [1, 1, 1, 1, 1, 2];
die_icon_size = 7.6;
die_icon_relief = 0.3;
die_icon_color = "SteelBlue";
die_icon_text_color = "Gainsboro";

die_basis = die_worst_case;
row_clearance = 1.5;

$fs = 0.2;
$fa = 4;

nozzle = 0.4;
layer_height = 0.2;
max_bridge = 50.0;

function beads(count) =
    count * nozzle - 1e-6;

wall = 1.6;
floor_thickness = 1.2;

outer_rounding = 2.0;
outer_top_chamfer = 0.0;
pocket_rounding = die_corner_radius;
pocket_floor_chamfer = 0.6;
pocket_lead_in = 0.6;
skirt_lead_in = 0.4;
void_overlap = 0.01;

label_size = 5.0;
label_depth = 0.6;

function pocket_width_for(basis) =
    basis + die_fit_clearance;
function tray_width_of(pocket) =
    pocket + 2 * wall + skirt_clearance;
function tray_width_for(basis) =
    tray_width_of(pocket_width_for(basis));

pocket_width = pocket_width_for(die_basis);

tray_wall_ratio = 0.5;
skirt_mode = "dice";
skirt_ratio = 0.3;

stack_clearance = 1.0;
skirt_clearance = 0.8;
lane_gap = 0.3;

tray_wall_height = die_worst_case * tray_wall_ratio;
die_protrusion = die_worst_case - tray_wall_height;

skirt_height = skirt_mode == "rim" ? die_protrusion + stack_clearance : die_worst_case * skirt_ratio;
tray_height = skirt_height + floor_thickness + tray_wall_height;
tray_pitch = skirt_mode == "rim" ? tray_height : floor_thickness + die_worst_case;

skirt_cavity_rounding = outer_rounding - wall;
skirt_flat_engagement = skirt_height - die_corner_radius;
rim_gap = die_protrusion - skirt_height;
die_side_play = (pocket_width - die_measured) / 2;
skirt_cavity_play = skirt_clearance / 2;
first_layer_wall = wall - skirt_lead_in;
rim_flat = wall - pocket_lead_in - outer_top_chamfer;
pocket_floor_flat = pocket_width - 2 * pocket_floor_chamfer;
die_contact_patch = die_measured - 2 * die_corner_radius;

assert(skirt_mode != "dice" || skirt_height < die_protrusion, "skirt_ratio too large for skirt_mode=dice: the skirt reaches the rim below");
assert(skirt_mode != "dice" || skirt_flat_engagement > 0, "skirt shallower than the die corner radius: it only grips the rounded corner");
assert(tray_wall_height > die_corner_radius, "tray wall shorter than the die corner radius: it only holds the rounded corner");
assert(skirt_cavity_rounding >= 0, "outer_rounding smaller than wall: the skirt corner would have no material");
assert(rim_flat >= beads(1), "pocket_lead_in + outer_top_chamfer leave less than one bead of flat rim");
assert(first_layer_wall >= beads(2), "skirt_lead_in leaves a first layer thinner than two beads");
assert(label_depth <= wall + skirt_clearance / 2 - beads(2), "label engraving leaves less than two beads of wall behind it");
assert(pocket_floor_flat > die_contact_patch, "pocket_floor_chamfer eats into the flat face the die lands on");
assert(tray_width_for(die_basis) - 2 * wall <= max_bridge, "skirt cavity is wider than PLA will bridge");

tray_width = tray_width_for(die_basis);
lane_pitch = tray_width + lane_gap;

card_width = 70.0;
card_height = 97.0;
card_thickness = 0.45;
card_thickness_worst = 0.48;
card_basis = card_thickness_worst;
card_slot_clearance = 1.5;
card_face_clearance = 2.5;
card_recess = 4.0;

tray_color = "Coral";
block_color = "MediumSeaGreen";

card_corner_radius = 3.0;
card_art_relief = 0.05;
card_logo_color = "Firebrick";
card_logo_ratio = 0.66;
card_band_ratio = 0.11;
card_label_ratio = 0.52;
card_label_font = "Liberation Sans:style=Bold";

card_kind_styles = [
    [
        "BASIC",
        ["Tan", "DarkRed", "Cornsilk"]
    ],
    [
        "SPELL",
        ["Gainsboro", "DarkGray", "White"]
    ],
    [
        "CREATURE",
        ["#2e2e2e", "#101010", "White"]
    ],
];

function card_style(kind) =
    card_kind_styles[search([kind], card_kind_styles)[0]][1];

card_wall_face = 2.0;
card_wall_side = 2.4;
card_wall_far = card_wall_side;
card_divider = 1.2;
card_slot_rounding = 1.0;

card_slot_inner_width = card_height + card_face_clearance;
card_slot_depth = card_width + card_recess;

base_card_stacks = [
    [
        ["BASIC", 3]
    ],
    [
        ["SPELL", 20]
    ],
    [
        ["CREATURE", 30]
    ],
];
expansion_card_stacks = [
    [
        ["BASIC", 1],
        ["SPELL", 4],
        ["CREATURE", 14],
        ["SPELL", 8],
        ["CREATURE", 18],
    ],
];
all_card_stacks = concat(base_card_stacks, expansion_card_stacks);

card_push_notch = true;
card_push_height = 20.0;
card_push_width = 2 * card_push_height;
card_push_roof_angle = 45;
card_push_rounding = 1.5;
card_island_relief = outer_rounding;
card_bottom_chamfer = 0.6;

card_push_apex = card_wall_far + card_push_height;
card_push_shoulder = card_push_apex - card_push_width / 2 * tan(card_push_roof_angle);

card_notch_width = card_push_width;
card_notch_gap = 6.0;
card_notch_apex_ratio = 0.8;
card_notch_radius = card_notch_width / 2;
card_notch_apex = card_push_notch ? card_push_apex + card_notch_gap : card_wall_far + card_notch_apex_ratio * card_slot_depth;
card_notch_centre = card_notch_apex + card_notch_radius;
card_floor_chamfer = 0.8;
card_lead_in = 1.0;

card_insertion = "top";
card_print_face = "far";

card_honeycomb = true;
card_honeycomb_dividers = true;
card_honeycomb_pitch = 7.0;
card_honeycomb_flat = 0.0;
card_honeycomb_rib = 2.07;
card_honeycomb_tip_angle = 60;
card_honeycomb_card_edge_margin = 10.0;
card_honeycomb_band = 4.0;
card_honeycomb_notch_gap = card_honeycomb_rib;
card_honeycomb_phase_steps = 12;

card_honeycomb_rhombus = card_honeycomb_flat == 0;
card_honeycomb_tip = card_honeycomb_pitch / 2 * tan(card_honeycomb_tip_angle);
card_honeycomb_inset = card_honeycomb_rib / 2;
card_honeycomb_cell_across = card_honeycomb_pitch - card_honeycomb_rib / (card_honeycomb_rhombus ? sin(card_honeycomb_tip_angle) : 1);
card_honeycomb_cell_along = card_honeycomb_flat + 2 * card_honeycomb_tip - card_honeycomb_rib / cos(card_honeycomb_tip_angle);
card_honeycomb_cell_flat = card_honeycomb_rhombus ? 0 : card_honeycomb_flat - card_honeycomb_rib * (1 - sin(card_honeycomb_tip_angle)) / cos(card_honeycomb_tip_angle);
card_honeycomb_row_pitch = card_honeycomb_flat + card_honeycomb_tip;

card_honeycomb_slides_down = card_insertion == "top";
card_honeycomb_long_axis_upright = card_print_face == "side";
card_honeycomb_turns = card_honeycomb_rhombus ? card_honeycomb_long_axis_upright : !card_honeycomb_slides_down;
card_honeycomb_cell_width = card_honeycomb_turns ? card_honeycomb_cell_along : card_honeycomb_cell_across;
card_honeycomb_cell_height = card_honeycomb_turns ? card_honeycomb_cell_across : card_honeycomb_cell_along;
card_honeycomb_pitch_u = card_honeycomb_turns ? card_honeycomb_row_pitch : card_honeycomb_pitch;
card_honeycomb_pitch_v = card_honeycomb_turns ? card_honeycomb_pitch : card_honeycomb_row_pitch;
card_honeycomb_stagger_u = card_honeycomb_turns ? 0 : card_honeycomb_pitch / 2;
card_honeycomb_stagger_v = card_honeycomb_turns ? card_honeycomb_pitch / 2 : 0;
card_honeycomb_leading_edge_bridge = card_honeycomb_turns ? card_honeycomb_cell_flat : 0;

card_honeycomb_half_width = card_height / 2 - card_honeycomb_card_edge_margin;
card_honeycomb_bottom = card_wall_far + card_honeycomb_band;
card_honeycomb_top = card_wall_far + card_slot_depth - card_honeycomb_band;
card_honeycomb_height = card_honeycomb_top - card_honeycomb_bottom;

assert(card_divider >= beads(3), "card divider thinner than three beads: it would print as a gap-filled sliver");
assert(card_insertion == "top" || card_insertion == "side", "card_insertion must be top or side: it decides which way the cells are turned so no cell edge runs parallel to the card edge that slides in");
assert(card_honeycomb_rib >= beads(3), "honeycomb rib thinner than three beads: the cells would print as a shredded wall");
assert(card_honeycomb_tip_angle >= 45, "honeycomb tip shallower than 45 degrees: the cell roof would need support");
assert(card_honeycomb_rhombus || card_honeycomb_cell_flat > 0, "honeycomb rib eats the whole cell flat: raise card_honeycomb_flat, drop the rib, or set the flat to 0 for a rhombus cell");
assert(card_honeycomb_cell_across > 0 && card_honeycomb_cell_along > 0, "honeycomb rib eats the whole cell: drop the rib or raise the pitch");
assert(!card_honeycomb_rhombus || card_honeycomb_tip_angle > 45, "a rhombus cell at exactly 45 degrees sits on the support limit on all four edges: raise card_honeycomb_tip_angle");
assert(card_print_face == "far" || card_print_face == "side" || card_print_face == "face", "card_print_face must be far, side or face: it names which wall lands on the bed");
assert(card_honeycomb_rhombus || card_print_face == "far", "a hexagon cell is only checked against the 45 degree rule with the card's long axis flat on the bed: a rhombus cell turns to suit any print face, a hexagon does not - see plan 13.4");
assert(card_honeycomb_height >= card_honeycomb_cell_height, "honeycomb window shorter than one cell: raise card_notch_apex_ratio or drop card_honeycomb_band");
assert(2 * card_honeycomb_half_width >= card_honeycomb_cell_width, "honeycomb window narrower than one cell");
assert(card_honeycomb_leading_edge_bridge <= max_bridge, "honeycomb cell edge facing the card's leading edge is wider than PLA will bridge");
assert(card_honeycomb_card_edge_margin > 0, "honeycomb reaching the card edge: the card corner would sweep across open cells on the way in");
assert(card_slot_rounding <= card_face_clearance / 2, "card slot corner fillet reaches past the card edge, so it squeezes the outermost cards instead of filling empty corner");
assert(card_wall_face >= beads(4), "card block face wall thinner than four beads, and it is the wall the honeycomb perforates");
assert(card_wall_side >= card_wall_face, "card block side wall thinner than the face wall: the side wall carries the width dimension and the lift notch, the face wall only spends depth");
assert(card_notch_apex_ratio > 0 && card_notch_apex_ratio < 1, "lift notch apex outside the wall it is cut into");
assert(card_notch_apex + card_notch_radius <= card_wall_far + card_slot_depth, "lift notch apex too high for its half circle to fit under the rim");
assert(card_notch_width < card_slot_inner_width, "lift notch wider than the slot it opens, so it would cut the side walls");
assert(card_recess > 0, "no recess: the card's trailing long edge would stand level with the mouth rim instead of below it - see plan 13.0");
assert(card_push_roof_angle >= 45, "push notch roof shallower than 45 degrees: it would need support");
assert(card_push_shoulder + 1e-6 >= card_wall_far, "push notch roof starts inside the wall the cards rest on: narrow it or raise card_push_height. Equality is the perfect triangle - the slope starts exactly at the surface the cards rest on");
assert(card_push_apex < card_notch_apex, "push notch reaches the lift notch: the face wall would be cut through from the mouth to the floor, leaving no band between them");
assert(card_push_width + 2 * card_honeycomb_card_edge_margin <= card_height, "push notch reaches within the card-edge margin of the card's short edges");
assert(card_wall_far >= beads(3), "far wall thinner than three beads, and the card's leading long edge lands on it");

tin_inner = 125.0;
tin_corner_radius = 7.5;
tin_safety_margin = 5.0;
envelope = tin_inner - tin_safety_margin;

function channel_length(dice_count, basis = die_basis) =
    dice_count * basis + row_clearance;
function tray_length(dice_count, basis = die_basis) =
    channel_length(dice_count, basis) + 2 * wall + skirt_clearance;

function lanes_in(width) =
    floor(width / lane_pitch);
function levels_in(height) =
    floor((height - die_protrusion) / tray_pitch);
function slots_in(region, dice_count) =
    tray_length(dice_count) <= region[0] ? lanes_in(region[1]) * levels_in(region[2]) : 0;

function stack_of(count) =
    count * card_basis;

function deck_kind(deck) =
    deck[0];
function deck_count(deck) =
    deck[1];
function deck_depth(deck) =
    stack_of(deck_count(deck));

function stack_count(stack) =
    sum([
        for (d = stack)
            deck_count(d)
    ]);
function stack_depth(stack) =
    stack_of(stack_count(stack));
function stack_summary(stack) =
    str_join([
        for (d = stack)
            str(deck_count(d), " ", deck_kind(d))
    ], " + ");
function deck_offset(stack, index) =
    index == 0 ? 0 : stack_of(sum([
        for (j = [0:index - 1])
            deck_count(stack[j])
    ]));

assert(len([
    for (s = all_card_stacks, d = s)
        if (is_undef(card_style(deck_kind(d))))
            d
]) == 0, "a card deck names a kind that has no entry in card_kind_styles");

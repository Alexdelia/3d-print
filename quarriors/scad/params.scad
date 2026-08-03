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

$fs = 0.4;
$fa = 4;

nozzle = 0.4;
layer_height = 0.2;
max_bridge = 50.0;

wall = 1.6;
floor_thickness = 1.2;

outer_rounding = 2.0;
outer_top_chamfer = 0.0;
pocket_rounding = die_corner_radius;
pocket_floor_chamfer = 0.6;
pocket_lead_in = 0.6;
skirt_lead_in = 0.4;

label_size = 5.0;
label_depth = 0.6;

function pocket_width_for(basis) = basis + die_fit_clearance;
function tray_width_of(pocket) = pocket + 2 * wall + skirt_clearance;
function tray_width_for(basis) = tray_width_of(pocket_width_for(basis));

pocket_width = pocket_width_for(die_basis);

tray_wall_ratio = 0.5;
skirt_mode = "dice";
skirt_ratio = 0.3;

stack_clearance = 1.0;
skirt_clearance = 0.8;
lane_gap = 0.3;

tray_wall_height = die_worst_case * tray_wall_ratio;
die_protrusion = die_worst_case - tray_wall_height;

skirt_height = skirt_mode == "rim" ? die_protrusion + stack_clearance
                                  : die_worst_case * skirt_ratio;
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

assert(skirt_mode != "dice" || skirt_height < die_protrusion,
       "skirt_ratio too large for skirt_mode=dice: the skirt reaches the rim below");
assert(skirt_mode != "dice" || skirt_flat_engagement > 0,
       "skirt shallower than the die corner radius: it only grips the rounded corner");
assert(tray_wall_height > die_corner_radius,
       "tray wall shorter than the die corner radius: it only holds the rounded corner");
assert(skirt_cavity_rounding >= 0,
       "outer_rounding smaller than wall: the skirt corner would have no material");
assert(rim_flat >= nozzle,
       "pocket_lead_in + outer_top_chamfer leave less than one bead of flat rim");
assert(first_layer_wall >= 2 * nozzle,
       "skirt_lead_in leaves a first layer thinner than two beads");
assert(label_depth <= wall + skirt_clearance / 2 - 2 * nozzle,
       "label engraving leaves less than two beads of wall behind it");
assert(pocket_floor_flat > die_contact_patch,
       "pocket_floor_chamfer eats into the flat face the die lands on");
assert(tray_width_for(die_basis) - 2 * wall <= max_bridge,
       "skirt cavity is wider than PLA will bridge");

tray_width = tray_width_for(die_basis);
lane_pitch = tray_width + lane_gap;

card_width = 70.0;
card_height = 97.0;
card_thickness = 0.62;
card_slot_clearance = 2.0;
card_face_clearance = 2.5;
card_block_wall_height = 70.0;

card_wall = 2.4;
card_slot_rounding = 3.0;
card_notch_width = 36.0;
card_notch_depth = 28.0;
card_notch_rounding = 8.0;
card_floor_chamfer = 0.8;
card_lead_in = 1.0;

assert(card_notch_depth < card_block_wall_height,
       "lift notch cut deeper than the wall is tall");
assert(card_notch_rounding <= card_notch_width / 2,
       "lift notch rounding larger than half its width");

tin_inner = 125.0;
tin_corner_radius = 7.5;
tin_safety_margin = 5.0;
envelope = tin_inner - tin_safety_margin;

function channel_length(dice_count, basis = die_basis) = dice_count * basis + row_clearance;
function tray_length(dice_count, basis = die_basis) =
    channel_length(dice_count, basis) + 2 * wall + skirt_clearance;

function lanes_in(width) = floor(width / lane_pitch);
function levels_in(height) = floor((height - die_protrusion) / tray_pitch);
function slots_in(region, dice_count) =
    tray_length(dice_count) <= region[0] ? lanes_in(region[1]) * levels_in(region[2]) : 0;

function stack_of(count) = count * card_thickness;
function well_height_for(count) = floor_thickness + stack_of(count) + card_slot_clearance;

gauge_pockets = [14.0, 14.5, 15.0, 15.5, 16.0];
gauge_target_length = 100.0;
gauge_depth = tray_wall_height;

gauge_wall = (gauge_target_length - sum(gauge_pockets)) / (len(gauge_pockets) + 1);
gauge_width = max(gauge_pockets) + 2 * gauge_wall;
gauge_height = floor_thickness + gauge_depth;

assert(gauge_wall >= 2 * wall,
       "gauge dividers thinner than two tray walls: the coupon would not represent a tray");

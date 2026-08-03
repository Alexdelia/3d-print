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

pocket = die_worst_case + die_fit_clearance;

wall = 1.6;
floor_thickness = 1.2;

tray_wall_ratio = 0.5;
skirt_mode = "dice";
skirt_ratio = 0.3;

stack_clearance = 0.5;
skirt_clearance = 0.5;
lane_gap = 0.3;

tray_wall_height = die_worst_case * tray_wall_ratio;
die_protrusion = die_worst_case - tray_wall_height;

skirt_height = skirt_mode == "rim" ? die_protrusion + stack_clearance
                                  : die_worst_case * skirt_ratio;
tray_height = skirt_height + floor_thickness + tray_wall_height;
tray_pitch = skirt_mode == "rim" ? tray_height : floor_thickness + die_worst_case;

skirt_flat_engagement = skirt_height - die_corner_radius;
rim_gap = die_protrusion - skirt_height;
die_side_play = (pocket + skirt_clearance - die_measured) / 2;

assert(skirt_mode != "dice" || skirt_height < die_protrusion,
       "skirt_ratio too large for skirt_mode=dice: the skirt reaches the rim below");
assert(skirt_mode != "dice" || skirt_flat_engagement > 0,
       "skirt shallower than the die corner radius: it only grips the rounded corner");

tray_width = pocket + 2 * wall + skirt_clearance;
lane_pitch = tray_width + lane_gap;

card_width = 70.0;
card_height = 97.0;
card_thickness = 0.62;
card_slot_clearance = 2.0;
card_face_clearance = 2.5;
card_block_wall_height = 70.0;

tin_inner = 125.0;
tin_corner_radius = 7.5;
tin_safety_margin = 5.0;
envelope = tin_inner - tin_safety_margin;

function tray_length(dice_count) = dice_count * pocket + 2 * wall + skirt_clearance;

function lanes_in(width) = floor(width / lane_pitch);
function levels_in(height) = floor((height - die_protrusion) / tray_pitch);
function slots_in(region, dice_count) =
    tray_length(dice_count) <= region[0] ? lanes_in(region[1]) * levels_in(region[2]) : 0;

function stack_of(count) = count * card_thickness;
function well_height_for(count) = floor_thickness + stack_of(count) + card_slot_clearance;

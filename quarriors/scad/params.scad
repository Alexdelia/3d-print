die_measured = 13.5;
die_worst_case = 14.0;
die_fit_clearance = 1.0;
die_corner_radius = 2.0;

pocket = die_worst_case + die_fit_clearance;

wall = 1.6;
floor_thickness = 1.2;
tray_wall_height = 7.0;

stack_clearance = 0.5;
skirt_clearance = 0.5;
lane_gap = 0.3;

skirt_height = die_worst_case + stack_clearance - tray_wall_height;
tray_height = tray_wall_height + floor_thickness + skirt_height;
tray_width = pocket + 2 * wall + skirt_clearance;
lane_pitch = tray_width + lane_gap;
die_protrusion = die_worst_case - tray_wall_height;

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
function levels_in(height) = floor((height - die_protrusion) / tray_height);
function slots_in(region, dice_count) =
    tray_length(dice_count) <= region[0] ? lanes_in(region[1]) * levels_in(region[2]) : 0;

function stack_of(count) = count * card_thickness;
function well_height_for(count) = floor_thickness + stack_of(count) + card_slot_clearance;

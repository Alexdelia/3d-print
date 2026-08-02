include <BOSL2/std.scad>
include <params.scad>

module die() {
    cuboid([die_measured, die_measured, die_measured],
           rounding = die_corner_radius, $fn = 32, anchor = BOTTOM);
}

module tray_with_dice(dice_count, filled) {
    dice_tray(dice_count);

    for (i = [0 : filled - 1])
        translate([wall + skirt_clearance / 2 + pocket * (i + 0.5),
                   tray_width / 2,
                   skirt_height + floor_thickness])
            die();
}

module dice_tray(dice_count) {
    length = tray_length(dice_count);
    skirt_inset = wall;
    pocket_inset = wall + skirt_clearance / 2;

    difference() {
        cube([length, tray_width, tray_height]);

        translate([skirt_inset, skirt_inset, -0.01])
            cube([length - 2 * skirt_inset, tray_width - 2 * skirt_inset, skirt_height + 0.01]);

        translate([pocket_inset, pocket_inset, skirt_height + floor_thickness])
            cube([dice_count * pocket, pocket, tray_wall_height + 0.01]);
    }
}

function card_slot_depths(stacks) = [for (s = stacks) s + card_slot_clearance];

function card_slot_offset(depths, index) =
    wall + (index == 0 ? 0 : sum([for (j = [0 : index - 1]) depths[j] + wall]));

function card_block_depth(stacks) =
    wall + sum([for (d = card_slot_depths(stacks)) d + wall]);

function card_block_width() = card_width + card_face_clearance + 2 * wall;

module card_block(stacks) {
    depths = card_slot_depths(stacks);
    inner_width = card_width + card_face_clearance;
    height = floor_thickness + card_block_wall_height;

    difference() {
        cube([card_block_depth(stacks), card_block_width(), height]);

        for (i = [0 : len(stacks) - 1])
            translate([card_slot_offset(depths, i), wall, floor_thickness])
                cube([depths[i], inner_width, height]);
    }
}

function card_well_length() = card_height + card_face_clearance + 2 * wall;
function card_well_width() = card_width + card_face_clearance + 2 * wall;

module card_well(card_count) {
    height = well_height_for(card_count);

    difference() {
        cube([card_well_length(), card_well_width(), height]);

        translate([wall, wall, floor_thickness])
            cube([card_height + card_face_clearance, card_width + card_face_clearance, height]);
    }
}

include <BOSL2/std.scad>
include <params.scad>

module die_body() {
    cuboid([die_measured, die_measured, die_measured],
           rounding = die_corner_radius, $fn = die_smoothness, anchor = BOTTOM);
}

module drop_outline(size) {
    hull() {
        translate([0, -size * 0.17]) circle(d = size * 0.58, $fn = 64);
        translate([0, size * 0.5]) circle(d = 0.01, $fn = 8);
    }
}

module die_icon_face(value) {
    color(die_icon_color)
        linear_extrude(die_icon_relief) drop_outline(die_icon_size);

    color(die_icon_text_color)
        translate([0, -die_icon_size * 0.17, die_icon_relief])
            linear_extrude(0.12)
                text(str(value), size = die_icon_size * 0.30,
                     halign = "center", valign = "center");
}

die_face_rotations = [
    [0, 0, 0],
    [180, 0, 0],
    [90, 0, 0],
    [-90, 0, 0],
    [0, 90, 0],
    [0, -90, 0],
];

die_face_spins = [0, 0, 0, 180, 90, -90];

function die_face_values(value) =
    is_num(value) ? [for (i = [0 : 5]) value] : value;

module on_die_face(index) {
    half = die_measured / 2;

    translate([0, 0, half])
        rotate(die_face_rotations[index])
            rotate([0, 0, die_face_spins[index]])
                translate([0, 0, half - die_icon_relief])
                    children();
}

module die(value = die_faces) {
    values = die_face_values(value);

    if (die_icon) {
        color(die_color)
            difference() {
                die_body();

                for (i = [0 : 5])
                    on_die_face(i)
                        linear_extrude(die_icon_relief + 0.01)
                            drop_outline(die_icon_size);
            }

        for (i = [0 : 5])
            on_die_face(i) die_icon_face(values[i]);
    } else {
        color(die_color) die_body();
    }
}

module tray_with_dice(dice_count, filled, tray_color) {
    color(tray_color) dice_tray(dice_count);

    for (i = [0 : filled - 1])
        translate([wall + skirt_clearance / 2 + row_clearance / 2 + die_measured * (i + 0.5),
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
            cube([channel_length(dice_count), pocket_width, tray_wall_height + 0.01]);
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

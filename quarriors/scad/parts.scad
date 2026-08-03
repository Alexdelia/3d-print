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

module engrave_front(txt, size, x, z, y_face, angle = 0) {
    translate([x, y_face + label_depth, z])
        rotate([90, 0, 0])
            linear_extrude(label_depth + 0.02)
                rotate([0, 0, angle])
                    text(txt, size = size, halign = "center", valign = "center");
}

module slot_void(length, width, depth, rounding, floor_chamfer, lead_in) {
    straight = depth - floor_chamfer - lead_in;

    assert(straight > 0, "slot too shallow for its floor chamfer plus lead-in");

    prismoid(size1 = [length + 2 * floor_chamfer, width + 2 * floor_chamfer],
             size2 = [length, width], h = floor_chamfer,
             rounding1 = rounding + floor_chamfer, rounding2 = rounding, anchor = BOTTOM);

    up(floor_chamfer)
        cuboid([length, width, straight], rounding = rounding, edges = "Z", anchor = BOTTOM);

    up(floor_chamfer + straight)
        prismoid(size1 = [length, width],
                 size2 = [length + 2 * lead_in, width + 2 * lead_in], h = lead_in,
                 rounding1 = rounding, rounding2 = rounding + lead_in, anchor = BOTTOM);

    up(depth)
        cuboid([length + 2 * lead_in, width + 2 * lead_in, 1],
               rounding = rounding + lead_in, edges = "Z", anchor = BOTTOM);
}

module skirt_void(length, width) {
    straight = skirt_height - skirt_lead_in;
    mouth_rounding = skirt_cavity_rounding + skirt_lead_in;

    down(1)
        cuboid([length + 2 * skirt_lead_in, width + 2 * skirt_lead_in, 1.001],
               rounding = mouth_rounding, edges = "Z", anchor = BOTTOM);

    prismoid(size1 = [length + 2 * skirt_lead_in, width + 2 * skirt_lead_in],
             size2 = [length, width], h = skirt_lead_in,
             rounding1 = mouth_rounding, rounding2 = skirt_cavity_rounding, anchor = BOTTOM);

    up(skirt_lead_in)
        cuboid([length, width, straight],
               rounding = skirt_cavity_rounding, edges = "Z", anchor = BOTTOM);
}

module outer_body(length, width, height) {
    if (outer_top_chamfer > 0)
        offset_sweep(rect([length, width], rounding = outer_rounding), height = height,
                     top = os_chamfer(width = outer_top_chamfer));
    else
        linear_extrude(height) rect([length, width], rounding = outer_rounding);
}

module dice_tray(dice_count, basis = die_basis, pocket = 0, label = "") {
    pocket_w = pocket > 0 ? pocket : pocket_width_for(basis);
    channel = channel_length(dice_count, basis);
    length = tray_length(dice_count, basis);
    width = tray_width_of(pocket_w);
    floor_top = skirt_height + floor_thickness;

    translate([length / 2, width / 2, 0])
        difference() {
            outer_body(length, width, tray_height);

            skirt_void(length - 2 * wall, width - 2 * wall);

            up(floor_top)
                slot_void(channel, pocket_w, tray_wall_height, pocket_rounding,
                          pocket_floor_chamfer, pocket_lead_in);

            if (label != "")
                engrave_front(label, label_size, 0, floor_top + tray_wall_height / 2,
                              -width / 2);
        }
}

module tray_with_dice(dice_count, filled, tray_color, basis = die_basis) {
    width = tray_width_for(basis);
    first = wall + skirt_clearance / 2 + row_clearance / 2;

    color(tray_color) dice_tray(dice_count, basis);

    for (i = [0 : filled - 1])
        translate([first + die_measured * (i + 0.5), width / 2,
                   skirt_height + floor_thickness])
            die();
}

function card_slot_depths(stacks) = [for (s = stacks) s + card_slot_clearance];

function card_slot_offset(depths, index) =
    card_wall + (index == 0 ? 0 : sum([for (j = [0 : index - 1]) depths[j] + card_wall]));

function card_block_depth(stacks) =
    card_wall + sum([for (d = card_slot_depths(stacks)) d + card_wall]);

function card_block_width() = card_width + card_face_clearance + 2 * card_wall;
function card_block_height() = floor_thickness + card_block_wall_height;

module card_lift_notch(span, height) {
    r = card_notch_rounding;
    half = card_notch_width / 2 - r;
    bottom = height - card_notch_depth;

    hull()
        for (s = [-1, 1])
            translate([0, s * half, bottom + r]) xcyl(r = r, l = span);

    translate([0, 0, bottom + r])
        cuboid([span, card_notch_width, card_notch_depth - r + 1], anchor = BOTTOM);
}

module card_block(stacks, label = "", notch = true) {
    depths = card_slot_depths(stacks);
    length = card_block_depth(stacks);
    width = card_block_width();
    height = card_block_height();
    inner_width = card_width + card_face_clearance;

    translate([length / 2, width / 2, 0])
        difference() {
            outer_body(length, width, height);

            for (i = [0 : len(stacks) - 1])
                translate([card_slot_offset(depths, i) + depths[i] / 2 - length / 2, 0,
                           floor_thickness])
                    slot_void(depths[i], inner_width, card_block_wall_height,
                              min(card_slot_rounding, depths[i] / 2 - 0.01),
                              card_floor_chamfer, card_lead_in);

            if (notch) card_lift_notch(length + 2, height);

            if (label != "")
                engrave_front(label, label_size, 0, height * 0.25, -width / 2, angle = 90);
        }
}

function card_well_length() = card_height + card_face_clearance + 2 * card_wall;
function card_well_width() = card_width + card_face_clearance + 2 * card_wall;

module card_well(card_count) {
    height = well_height_for(card_count);

    translate([card_well_length() / 2, card_well_width() / 2, 0])
        difference() {
            outer_body(card_well_length(), card_well_width(), height);

            up(floor_thickness)
                slot_void(card_height + card_face_clearance, card_width + card_face_clearance,
                          height - floor_thickness, card_slot_rounding,
                          card_floor_chamfer, card_lead_in);
        }
}

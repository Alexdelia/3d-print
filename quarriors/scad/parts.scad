include <BOSL2/std.scad>
include <params.scad>

module die_body() {
    cuboid([die_measured, die_measured, die_measured], rounding = die_corner_radius, $fn = die_smoothness, anchor = BOTTOM);
}

module drop_outline(size) {
    hull() {
        translate([0, -size * 0.17])
            circle(d = size * 0.58, $fn = 64);
        translate([0, size * 0.5])
            circle(d = 0.01, $fn = 8);
    }
}

module die_icon_face(value) {
    color(die_icon_color)
        linear_extrude(die_icon_relief)
            drop_outline(die_icon_size);

    color(die_icon_text_color)
        translate([0, -die_icon_size * 0.17, die_icon_relief])
            linear_extrude(0.12)
                text(str(value), size = die_icon_size * 0.30, halign = "center", valign = "center");
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
    is_num(value) ? [
        for (i = [0:5])
            value
    ] : value;

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

                for(i = [0:5])
                    on_die_face(i)
                        linear_extrude(die_icon_relief + 0.01)
                            drop_outline(die_icon_size);
            }

        for(i = [0:5])
            on_die_face(i)
                die_icon_face(values[i]);
    } else {
        color(die_color)
            die_body();
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

    prismoid(size1 = [length + 2 * floor_chamfer, width + 2 * floor_chamfer], size2 = [length, width], h = floor_chamfer, rounding1 = rounding + floor_chamfer, rounding2 = rounding, anchor = BOTTOM);

    up(floor_chamfer)
        cuboid([length, width, straight], rounding = rounding, edges = "Z", anchor = BOTTOM);

    up(floor_chamfer + straight)
        prismoid(size1 = [length, width], size2 = [length + 2 * lead_in, width + 2 * lead_in], h = lead_in, rounding1 = rounding, rounding2 = rounding + lead_in, anchor = BOTTOM);

    up(depth)
        cuboid([length + 2 * lead_in, width + 2 * lead_in, 1], rounding = rounding + lead_in, edges = "Z", anchor = BOTTOM);
}

module skirt_void(length, width) {
    straight = skirt_height - skirt_lead_in;
    mouth_rounding = skirt_cavity_rounding + skirt_lead_in;

    down(1)
        cuboid([length + 2 * skirt_lead_in, width + 2 * skirt_lead_in, 1.001], rounding = mouth_rounding, edges = "Z", anchor = BOTTOM);

    prismoid(size1 = [length + 2 * skirt_lead_in, width + 2 * skirt_lead_in], size2 = [length, width], h = skirt_lead_in, rounding1 = mouth_rounding, rounding2 = skirt_cavity_rounding, anchor = BOTTOM);

    up(skirt_lead_in)
        cuboid([length, width, straight], rounding = skirt_cavity_rounding, edges = "Z", anchor = BOTTOM);
}

module outer_body(length, width, height) {
    if (outer_top_chamfer > 0)
        offset_sweep(rect([length, width], rounding = outer_rounding), height = height, top = os_chamfer(width = outer_top_chamfer));
    else
        linear_extrude(height)
            rect([length, width], rounding = outer_rounding);
}

module dice_row(count, width) {
    first = wall + skirt_clearance / 2 + row_clearance / 2;

    for(i = [0:count - 1])
        translate([first + die_measured * (i + 0.5), width / 2, skirt_height + floor_thickness])
            die();
}

module dice_tray(dice_count, basis = die_basis, pocket = 0, label = "", filled = -1, part_color = tray_color) {
    pocket_w = pocket > 0 ? pocket : pocket_width_for(basis);
    channel = channel_length(dice_count, basis);
    length = tray_length(dice_count, basis);
    width = tray_width_of(pocket_w);
    floor_top = skirt_height + floor_thickness;
    shown = filled >= 0 ? filled : (show_dice ? dice_count : 0);

    translate([length / 2, width / 2, 0])
        color(part_color)
            difference() {
                outer_body(length, width, tray_height);

                skirt_void(length - 2 * wall, width - 2 * wall);

                up(floor_top)
                    slot_void(channel, pocket_w, tray_wall_height, pocket_rounding, pocket_floor_chamfer, pocket_lead_in);

                if (label != "")
                    engrave_front(label, label_size, 0, floor_top + tray_wall_height / 2, -width / 2);
            }

    if (shown > 0)
        dice_row(shown, width);
}

function card_slot_depths(stacks) =
    [
        for (s = stacks)
            stack_depth(s) + card_slot_clearance
    ];

function card_slot_offset(depths, index) =
    card_wall + (index == 0 ? 0 : sum([
        for (j = [0:index - 1])
            depths[j] + card_divider
    ]));

function card_block_depth(stacks) =
    2 * card_wall + sum(card_slot_depths(stacks)) + (len(stacks) - 1) * card_divider;

function card_block_width() =
    card_width + card_face_clearance + 2 * card_wall;
function card_block_height() =
    floor_thickness + card_block_wall_height;

module quiddity_logo(size) {
    difference() {
        circle(d = size, $fn = 96);
        circle(d = size * 0.5, $fn = 96);
    }

    hull() {
        translate([0, -size * 0.1])
            square([size * 0.16, 0.01], center = true);

        translate([0, -size * 0.62])
            square([size * 0.42, 0.01], center = true);
    }
}

module card_back(kind, relief) {
    style = card_style(kind);
    band = card_height * card_band_ratio;

    color(style[1])
        linear_extrude(relief)
            translate([0, band / 2])
                square([card_width, band], center = true);

    color(style[2])
        linear_extrude(2 * relief)
            translate([0, band / 2])
                text(kind, size = band * card_label_ratio, font = card_label_font, halign = "center", valign = "center");

    color(card_logo_color)
        linear_extrude(relief)
            translate([0, band + (card_height - band) / 2])
                quiddity_logo(card_width * card_logo_ratio);
}

module card_deck(deck) {
    color(card_style(deck_kind(deck))[0])
        cuboid([deck_depth(deck), card_width, card_height], rounding = card_corner_radius, edges = "X", anchor = BOTTOM);
}

module card_pack(stack) {
    depth = stack_depth(stack);
    outermost = [
        [1, deck_kind(stack[len(stack) - 1])],
        [-1, deck_kind(stack[0])],
    ];

    for(i = [0:len(stack) - 1])
        translate([deck_offset(stack, i) + deck_depth(stack[i]) / 2 - depth / 2, 0, 0])
            card_deck(stack[i]);

    for(end = outermost)
        rotate([0, 0, end[0] > 0 ? 0 : 180])
            translate([depth / 2, 0, 0])
                rotate([90, 0, 90])
                    card_back(end[1], card_art_relief);
}

module card_lift_notch(span, height) {
    r = card_notch_rounding;
    half = card_notch_width / 2 - r;
    bottom = height - card_notch_depth;

    hull()
        for(s = [-1, 1])
            translate([0, s * half, bottom + r])
                xcyl(r = r, l = span);

    translate([0, 0, bottom + r])
        cuboid([span, card_notch_width, card_notch_depth - r + 1], anchor = BOTTOM);
}

module card_block(stacks, label = "", notch = true, part_color = block_color, loaded = show_cards) {
    depths = card_slot_depths(stacks);
    length = card_block_depth(stacks);
    width = card_block_width();
    height = card_block_height();
    inner_width = card_width + card_face_clearance;

    translate([length / 2, width / 2, 0]) {
        color(part_color)
            difference() {
                outer_body(length, width, height);

                for(i = [0:len(stacks) - 1])
                    translate([card_slot_offset(depths, i) + depths[i] / 2 - length / 2, 0, floor_thickness])
                        slot_void(depths[i], inner_width, card_block_wall_height, min(card_slot_rounding, depths[i] / 2 - 0.01), card_floor_chamfer, card_lead_in);

                if (notch)
                    card_lift_notch(length + 2, height);

                if (label != "")
                    engrave_front(label, label_size, 0, height * 0.25, -width / 2, angle = 90);
            }

        if (loaded)
            for(i = [0:len(stacks) - 1])
                translate([card_slot_offset(depths, i) + depths[i] / 2 - length / 2, 0, floor_thickness])
                    card_pack(stacks[i]);
    }
}

function card_reach() =
    floor_thickness + card_height;

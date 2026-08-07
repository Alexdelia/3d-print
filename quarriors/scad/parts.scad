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
    breakout = lead_in + 1;

    assert(straight > 0, "slot too shallow for its floor chamfer plus lead-in");

    prismoid(size1 = [length + 2 * floor_chamfer, width + 2 * floor_chamfer], size2 = [length, width], h = floor_chamfer, rounding1 = rounding + floor_chamfer, rounding2 = rounding, anchor = BOTTOM);

    up(floor_chamfer - void_overlap)
        cuboid([length, width, straight + 2 * void_overlap], rounding = rounding, edges = "Z", anchor = BOTTOM);

    up(floor_chamfer + straight)
        prismoid(size1 = [length, width], size2 = [length + 2 * breakout, width + 2 * breakout], h = breakout, rounding1 = rounding, rounding2 = rounding + breakout, anchor = BOTTOM);
}

module skirt_void(length, width) {
    straight = skirt_height - skirt_lead_in;
    breakout = skirt_lead_in + 1;

    down(breakout - skirt_lead_in)
        prismoid(size1 = [length + 2 * breakout, width + 2 * breakout], size2 = [length, width], h = breakout, rounding1 = skirt_cavity_rounding + breakout, rounding2 = skirt_cavity_rounding, anchor = BOTTOM);

    up(skirt_lead_in - void_overlap)
        cuboid([length, width, straight + void_overlap], rounding = skirt_cavity_rounding, edges = "Z", anchor = BOTTOM);
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
    card_wall_face + (index == 0 ? 0 : sum([
        for (j = [0:index - 1])
            depths[j] + card_divider
    ]));

function card_block_depth(stacks) =
    2 * card_wall_face + sum(card_slot_depths(stacks)) + (len(stacks) - 1) * card_divider;

function card_block_width() =
    card_slot_inner_width + 2 * card_wall_side;

assert(card_block_width() >= tray_length(5), "card block narrower than a 5-die tray: the strip beside it can then only take stub trays, which costs 21 of the 35 slots - see plan 12.2");
function card_block_height() =
    card_wall_far + card_slot_depth;

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
        cuboid([deck_depth(deck), card_height, card_width], rounding = card_corner_radius, edges = "X", anchor = BOTTOM);
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
        mirror([end[0] > 0 ? 0 : 1, 0, 0])
            translate([depth / 2, -card_height / 2, card_width / 2])
                rotate([0, 90, 0])
                    card_back(end[1], card_art_relief);
}

module card_lift_notch(span, height) {
    translate([0, 0, card_notch_apex + card_notch_radius]) {
        xcyl(r = card_notch_radius, l = span);

        cuboid([span, card_notch_width, height - card_notch_apex - card_notch_radius + 1], anchor = BOTTOM);
    }
}

module card_push_void(span) {
    half = card_push_width / 2;

    rotate([90, 0, 90])
        linear_extrude(span, center = true)
            polygon([
                [-half, -1],
                [half, -1],
                [half, card_push_shoulder],
                [0, card_push_apex],
                [-half, card_push_shoulder],
            ]);
}

function honeycomb_tile() =
    let (across = card_honeycomb_pitch / 2, flat = card_honeycomb_flat / 2, tip = card_honeycomb_flat / 2 + card_honeycomb_tip)
        card_honeycomb_rhombus ? [
            [across, 0],
            [0, tip],
            [-across, 0],
            [0, -tip],
        ] : [
            [across, -flat],
            [across, flat],
            [0, tip],
            [-across, flat],
            [-across, -flat],
            [0, -tip],
        ];

function honeycomb_cell_points(u, v) =
    let (half_width = card_honeycomb_cell_width / 2, half_height = card_honeycomb_cell_height / 2, half_flat = card_honeycomb_cell_flat / 2)
        card_honeycomb_rhombus ? [
            [u + half_width, v],
            [u, v + half_height],
            [u - half_width, v],
            [u, v - half_height],
        ] : card_honeycomb_turns ? [
            [u - half_flat, v + half_height],
            [u + half_flat, v + half_height],
            [u + half_width, v],
            [u + half_flat, v - half_height],
            [u - half_flat, v - half_height],
            [u - half_width, v],
        ] : [
            [u + half_width, v - half_flat],
            [u + half_width, v + half_flat],
            [u, v + half_height],
            [u - half_width, v + half_flat],
            [u - half_width, v - half_flat],
            [u, v - half_height],
        ];

function segment_distance(p, a, b) =
    let (edge = b - a, span = edge * edge, t = span == 0 ? 0 : max(0, min(1, ((p - a) * edge) / span)))
        norm(p - (a + t * edge));

function outline_distance(p, outline) =
    min([
        for (i = [0:len(outline) - 1])
            segment_distance(p, outline[i], outline[(i + 1) % len(outline)])
    ]);

function count_where(list) =
    len([
        for (flagged = list)
            if (flagged)
                1
    ]);

function honeycomb_columns() =
    floor((card_honeycomb_half_width - card_honeycomb_cell_width / 2) / card_honeycomb_pitch_u) + 1;

function honeycomb_rows() =
    floor((card_honeycomb_height - card_honeycomb_cell_height) / card_honeycomb_pitch_v) + 1;

function honeycomb_lowest() =
    card_honeycomb_bottom + card_honeycomb_cell_height / 2 + (card_honeycomb_height - card_honeycomb_cell_height - (honeycomb_rows() - 1) * card_honeycomb_pitch_v) / 2;

function honeycomb_in_window(outline) =
    count_where([
        for (p = outline)
            abs(p[0]) > card_honeycomb_half_width || p[1] < card_honeycomb_bottom || p[1] > card_honeycomb_top
    ]) == 0;

function honeycomb_clears_push(outline) =
    !card_push_notch || count_where([
        for (p = outline)
            abs(p[0]) + p[1] < card_push_apex + card_honeycomb_notch_gap * sqrt(2)
    ]) == 0;

function honeycomb_clears_lift(outline) =
    outline_distance([0, card_notch_centre], outline) >= card_notch_radius + card_honeycomb_notch_gap && count_where([
        for (p = outline)
            abs(p[0]) < card_notch_radius + card_honeycomb_notch_gap && p[1] > card_notch_centre
    ]) == 0;

function honeycomb_holds(u, v) =
    let (outline = honeycomb_cell_points(u, v))
        honeycomb_in_window(outline) && honeycomb_clears_push(outline) && honeycomb_clears_lift(outline);

function honeycomb_centres() =
    [
        for (column = [-honeycomb_columns():honeycomb_columns()], row = [0:honeycomb_rows()])
            let (u = column * card_honeycomb_pitch_u + (row % 2 == 0 ? 0 : card_honeycomb_stagger_u), v = honeycomb_lowest() + row * card_honeycomb_pitch_v + (column % 2 == 0 ? 0 : card_honeycomb_stagger_v))
                if (honeycomb_holds(u, v))
                    [u, v]
    ];

module honeycomb_cell() {
    rotate(card_honeycomb_slides_down ? 0 : 90)
        offset(delta = -card_honeycomb_inset)
            polygon(honeycomb_tile());
}

module honeycomb_cells() {
    for(centre = honeycomb_centres())
        translate(centre)
            honeycomb_cell();
}

module card_honeycomb_void(length) {
    if (card_honeycomb_dividers)
        rotate([90, 0, 90])
            linear_extrude(length + 2, center = true)
                honeycomb_cells();
    else
        for(side = [-1, 1])
            translate([side * (length - card_wall_face) / 2, 0, 0])
                rotate([90, 0, 90])
                    linear_extrude(card_wall_face + 2, center = true)
                        honeycomb_cells();
}

module card_block(stacks, label = "", notch = true, part_color = block_color, loaded = show_cards) {
    depths = card_slot_depths(stacks);
    length = card_block_depth(stacks);
    width = card_block_width();
    height = card_block_height();
    inner_width = card_slot_inner_width;

    translate([length / 2, width / 2, 0]) {
        color(part_color)
            difference() {
                outer_body(length, width, height);

                for(i = [0:len(stacks) - 1])
                    translate([card_slot_offset(depths, i) + depths[i] / 2 - length / 2, 0, card_wall_far])
                        slot_void(depths[i], inner_width, card_slot_depth, min(card_slot_rounding, depths[i] / 2 - 0.01), card_floor_chamfer, card_lead_in);

                if (notch)
                    card_lift_notch(length + 2, height);

                if (card_push_notch)
                    card_push_void(length + 2);

                if (card_honeycomb)
                    card_honeycomb_void(length);

                if (label != "")
                    engrave_front(label, label_size, 0, height * 0.25, -width / 2, angle = 90);
            }

        if (loaded)
            for(i = [0:len(stacks) - 1])
                translate([card_slot_offset(depths, i) + depths[i] / 2 - length / 2, 0, card_wall_far])
                    card_pack(stacks[i]);
    }
}

function card_reach() =
    card_block_height();

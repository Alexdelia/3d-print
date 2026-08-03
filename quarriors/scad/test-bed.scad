include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

plate_gap = 8;

test_bed_trays = [
    [5, die_measured],
    [6, die_measured],
    [5, die_worst_case],
];

function plate_offset(index) =
    index == 0 ? 0
               : sum([for (j = [0 : index - 1])
                        tray_width_for(test_bed_trays[j][1]) + plate_gap]);

part = -1;

for (i = [0 : len(test_bed_trays) - 1])
    if (part < 0 || part == i)
        translate([0, part < 0 ? plate_offset(i) : 0, 0])
            dice_tray(test_bed_trays[i][0], test_bed_trays[i][1]);

plate_length = max([for (t = test_bed_trays) tray_length(t[0], t[1])]);
plate_width = plate_offset(len(test_bed_trays)) - plate_gap;

echo(str("skirt mode           ", skirt_mode, ", skirt ", skirt_height));
echo(str("part height          ", tray_height));
echo(str("stack pitch          ", tray_pitch));
echo(str("row clearance        ", row_clearance));

for (i = [0 : len(test_bed_trays) - 1])
    echo(str("part ", i, "  ", test_bed_trays[i][0], " dice, basis ",
             test_bed_trays[i][1],
             "  ", tray_length(test_bed_trays[i][0], test_bed_trays[i][1]),
             " x ", tray_width_for(test_bed_trays[i][1]),
             " x ", tray_height,
             "  channel ", channel_length(test_bed_trays[i][0], test_bed_trays[i][1]),
             "  pocket ", pocket_width_for(test_bed_trays[i][1])));

echo(str("plate               ", plate_length, " x ", plate_width));

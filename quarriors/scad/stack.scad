include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

section = false;
explode = 0;

stack_levels = [
    ["Coral", 5],
    ["MediumSeaGreen", 5],
    ["SteelBlue", 3]
];

module stack_scene() {
    for(i = [0:len(stack_levels) - 1])
        translate([0, 0, i * (tray_pitch + explode)])
            tray_with_dice(5, stack_levels[i][1], stack_levels[i][0]);
}

if (section)
    intersection() {
        stack_scene();
        translate([-10, tray_width / 2, -10])
            cube([tray_length(5) + 20, tray_width, 3 * tray_pitch + explode + 20]);
    }
else
    stack_scene();

rests_on = skirt_mode == "rim" ? "rim of tray below" : "dice tops below";

echo(str("skirt mode           ", skirt_mode, ", rests on ", rests_on));
echo(str("wall ratio           ", tray_wall_ratio, " -> wall ", tray_wall_height));
echo(str("skirt ratio          ", skirt_ratio, " -> skirt ", skirt_height));
echo(str("die corner radius    ", die_corner_radius));
echo(str("grip on flat side    ", skirt_flat_engagement));
echo(str("gap between rims     ", rim_gap));
echo(str("side play per side   ", die_side_play));
echo(str("roll before rims hit ", atan(rim_gap / (tray_width / 2)), " deg"));
echo(str("pitch before rims hit", atan(rim_gap / (tray_length(5) / 2)), " deg"));
echo(str("part height          ", tray_height));
echo(str("stack pitch          ", tray_pitch));
echo(str("loaded stack of ", len(stack_levels), "     rim ", (len(stack_levels) - 1) * tray_pitch + tray_height, ", dice top ", (len(stack_levels) - 1) * tray_pitch + skirt_height + floor_thickness + die_measured));
echo(str("column of 7          ", 6 * tray_pitch + tray_height + die_protrusion));
echo(str("skirt bridge span    ", tray_width - 2 * wall));
echo(str("bridge height off bed", skirt_height));

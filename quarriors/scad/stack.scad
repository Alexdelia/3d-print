include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

section = false;
explode = 0;

module stack_scene() {
    tray_with_dice(5, 4, "Coral");

    translate([0, 0, tray_pitch + explode])
        tray_with_dice(5, 3, "MediumSeaGreen");
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
gap_between_rims = tray_pitch - tray_height;

echo(str("skirt mode           ", skirt_mode, ", rests on ", rests_on));
echo(str("wall ratio           ", tray_wall_ratio, " of die"));
echo(str("wall height          ", tray_wall_height));
echo(str("skirt height         ", skirt_height));
echo(str("part height          ", tray_height));
echo(str("stack pitch          ", tray_pitch));
echo(str("die protrusion       ", die_protrusion));
echo(str("gap between rims     ", gap_between_rims));
echo(str("column of 7          ", 6 * tray_pitch + tray_height + die_protrusion));
echo(str("skirt bridge span    ", tray_width - 2 * wall));
echo(str("bed contact area     ", 2 * (tray_length(5) + tray_width) * wall));

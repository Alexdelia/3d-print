include <BOSL2/std.scad>
include <params.scad>
include <parts.scad>

section = false;
explode = 0;

module stack_scene() {
    tray_with_dice(5, 4, "Coral");

    translate([0, 0, tray_height + explode])
        tray_with_dice(5, 3, "MediumSeaGreen");
}

if (section)
    intersection() {
        stack_scene();
        translate([-10, tray_width / 2, -10])
            cube([tray_length(5) + 20, tray_width, 3 * tray_height + explode + 20]);
    }
else
    stack_scene();

echo(str("stack pitch          ", tray_height));
echo(str("rim height           ", tray_height));
echo(str("die top above floor  ", skirt_height + floor_thickness + die_measured));
echo(str("die protrusion       ", skirt_height + floor_thickness + die_measured - tray_height));
echo(str("skirt cavity ceiling ", tray_height + skirt_height));
echo(str("clearance over dice  ", tray_height + skirt_height - (skirt_height + floor_thickness + die_measured)));
echo(str("skirt bridge span    ", tray_width - 2 * wall));

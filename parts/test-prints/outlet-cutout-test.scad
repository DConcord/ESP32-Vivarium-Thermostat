// Test plate for the NEMA 5-15R snap-in outlet: the same cutout and thinned wall as the
// enclosure's back wall (values copied from ../main-enclosure/main-enclosure.scad; keep in sync).
// Print flat, outside face down. Push the outlet in from the smooth (outside) face; the side
// clips should spring out behind the thinned area and hold it firmly.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
eps = 0.01;

// ---- parameters (same as the enclosure) ----
wall = 3;                       // enclosure wall thickness
outlet_cut = [23.7, 23.7];      // cutout (measured body 23.3 + 0.4 clearance)
outlet_panel_t = 2.0;           // wall thinned to this around the cutout (clips grip up to 2.21)
outlet_pocket = [31, 31];       // thinned area, on the inside face
plate = [45, 45];               // test plate size
corner_r = 3;
label_depth = 0.6;

// ---- asserts ----
assert(outlet_panel_t < 2.21, "thinned wall must be thinner than the clips' grip range");
assert(outlet_pocket.x < plate.x - 4 && outlet_pocket.y < plate.y - 4, "pocket too close to the plate edge");
assert(outlet_pocket.x > outlet_cut.x + 4, "pocket must extend past the cutout to clear the clips");

// ---- geometry: outside face on Z = 0, inside face (with the pocket) on top ----
difference() {
  cuboid([plate.x, plate.y, wall], rounding=corner_r, edges="Z", anchor=BOT);
  // cutout
  cuboid([outlet_cut.x, outlet_cut.y, 3*wall], anchor=CENTER);
  // thinning pocket from the inside face
  translate([0, 0, outlet_panel_t]) cuboid([outlet_pocket.x, outlet_pocket.y, wall], anchor=BOT);
  // label on the inside face, in the margin below the pocket
  translate([0, -(outlet_pocket.y/2 + (plate.y - outlet_pocket.y)/4), wall - label_depth])
    linear_extrude(label_depth + eps)
      text(str(outlet_cut.x, " / ", outlet_panel_t), size=3.2, halign="center", valign="center");
}

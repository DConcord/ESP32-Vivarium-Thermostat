// Printed washers so the #6 and #8 self-tapping screws from the cupboard kit don't bottom out.
// One size for both screws: a 4 mm spacer and a 1 mm shim, stacked to suit.
//   SSR (2x #8 x 3/4"): screw reach = 19.05 - SSR tab thickness - stack; aim for 7-9 mm (pilot 9.5).
//   Pod bracket (2x #6 x 1/2", through the PVC wall): reach = 12.7 - wall - stack; aim for 4.5-5.5 (pilot 6).
// Print flat; no supports.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "set";                   // "spacer" | "shim" | "set" (print plate)

// ---- parameters ----
hole_d = 4.6;                   // clears #8 (4.2) and #6 (3.5)
od = 9;                         // covers a #8 pan head (~8.4)
spacer_t = 4;  shim_t = 1;
chamfer = 0.4;
set_spacers = 4;  set_shims = 12;  pitch = od + 3;

// ---- asserts ----
assert(od - hole_d >= 4, "washer ring too thin");

module washer(t) {
  difference() {
    cyl(d=od, h=t, chamfer2=min(chamfer, t/3), anchor=BOT);
    translate([0, 0, -0.01]) cyl(d=hole_d, h=t + 0.02, anchor=BOT);
  }
}

if (part == "spacer") washer(spacer_t);
else if (part == "shim") washer(shim_t);
else if (part == "set") {
  n = set_spacers + set_shims;  cols = 4;
  for (i = [0:n-1]) translate([(i % cols)*pitch, floor(i / cols)*pitch, 0])
    washer(i < set_spacers ? spacer_t : shim_t);
}

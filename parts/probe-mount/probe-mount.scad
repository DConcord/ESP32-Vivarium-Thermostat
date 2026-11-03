// Wall holster for a DS18B20 probe (5.85 x 33.6 mm steel tip, 6.4 x 16 mm sleeve), hanging tip-
// down on the inside of the PVC wall. The steel tip sits in a ventilated cage, standing off the
// wall, so it reads the air (not the wall) and the snake can't hook it. Drop the probe in from
// the top: the tip rests on a floor ring at the bottom of the cage (a 4 mm hole keeps air moving
// past it), and a slotted clip above the cage grips the 6.4 mm sleeve. The sleeve is only 0.55 mm
// fatter than the steel, so nothing relies on that step. Two screws from outside the PVC into 2.5
// mm pilots (same depth as the IR pod bracket: M3 x 10-12, or #6 x 1/2" with the printed shims).
// Print standing upright, as modelled; no supports.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "mount";                 // "mount" | "check" (with a mock probe)
eps = 0.01;

// ---- parameters ----
probe_d = 5.85;  probe_l = 33.6; // steel tip (measured)
sleeve_d = 6.4;  sleeve_l = 16; // black sleeve just above the steel (measured)
clip_id = 6.15;                 // clip bore: the steel must slide through, the sleeve must pinch.
                                // Set from parts/test-prints/probe-clip-test (6.0 / 6.15 / 6.3)
cage_id = 11;  tube_t = 1.6;    // ventilated cage around the tip
floor_t = 1.6;  stop_d = 4;     // floor ring the tip rests on
slot_w = 4;  slot_n = 3;        // vertical windows (not on the wall side)
clip_h = 12;  clip_gap = 3.5;   // slotted clip on the sleeve, opening to the front
sleeve_clr = 1;                 // clip starts this far above the top of the steel
plate = [22, 7];                // width, thickness (screw plate against the wall)
pilot_d = 2.5;  pilot_depth = 6;  screw_inset = 6;

// ---- derived (Z up, wall face at Y = 0, probe axis at X = 0) ----
axis_y = plate.y + tube_t + cage_id/2;         // probe axis distance from the wall
clip_z0 = floor_t + probe_l + sleeve_clr;      // clip grips the sleeve from here up
cone_h = (cage_id - clip_id)/2;                // 45-degree roof of the cage, prints without support
cage_top = clip_z0 - cone_h;
total_h = clip_z0 + clip_h;
od = cage_id + 2*tube_t;
slot_z0 = floor_t + 2;
slot_h = cage_top - slot_z0 - 2;
screw_z = [screw_inset, total_h - screw_inset];

// ---- asserts ----
assert(cage_id/2 - probe_d/2 >= 2, "tip too close to the cage");
assert(axis_y - probe_d/2 >= 10, "tip too close to the wall");
assert(pilot_depth < plate.y - 0.8, "pilot breaks through the plate");
assert(stop_d < probe_d - 1.2, "floor hole lets the tip through");
assert(clip_id > probe_d && clip_id < sleeve_d, "clip must pass the steel and pinch the sleeve");
assert(clip_gap < clip_id - 1.5, "clip opening too wide to hold");
assert(slot_w <= 4, "slots wide enough for a snake to get into");
assert(slot_h > 20, "slots too short");
assert(sleeve_clr + clip_h <= sleeve_l - 1, "clip runs past the sleeve");

module mount() {
  difference() {
    union() {
      // screw plate
      translate([-plate.x/2, 0, 0]) cube([plate.x, plate.y + eps, total_h]);
      // cage + clip as one tube
      translate([0, axis_y, 0]) cyl(d=od, h=total_h, anchor=BOT);
      // web tying the tube to the plate
      translate([-od/4, plate.y - eps, 0]) cube([od/2, axis_y - plate.y, total_h]);
    }
    translate([0, axis_y, 0]) {
      // hole in the floor ring
      translate([0, 0, -eps]) cyl(d=stop_d, h=floor_t + 2*eps, anchor=BOT);
      // cage bore, closing in at 45 degrees to the clip bore
      translate([0, 0, floor_t]) cyl(d=cage_id, h=cage_top - floor_t + eps, anchor=BOT);
      translate([0, 0, cage_top]) cyl(d1=cage_id, d2=clip_id, h=cone_h + eps, anchor=BOT);
      // clip bore and its front opening
      translate([0, 0, clip_z0]) cyl(d=clip_id, h=clip_h + eps, anchor=BOT);
      translate([-clip_gap/2, 0, clip_z0]) cube([clip_gap, od, clip_h + eps]);
      // ventilation slots, spread over the front half
      for (i = [0:slot_n-1]) rotate([0, 0, -60 + i*60])
        translate([0, cage_id/2 - 0.5, slot_z0]) cuboid([slot_w, tube_t + 2, slot_h], anchor=BOT+FRONT);
    }
    // wall-screw pilots from the wall face
    for (z = screw_z) translate([0, -eps, z]) cyl(d=pilot_d, h=pilot_depth + eps, orient=BACK, anchor=BOT);
  }
}

if (part == "mount") mount();
else if (part == "check") {
  mount();
  translate([0, axis_y, floor_t]) {
    color("Silver") cyl(d=probe_d, h=probe_l, anchor=BOT, rounding1=1);
    color("#222") translate([0, 0, probe_l]) cyl(d=sleeve_d, h=25, anchor=BOT);
  }
}

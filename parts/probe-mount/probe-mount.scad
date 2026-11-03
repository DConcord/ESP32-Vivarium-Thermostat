// Wall holster for a 6 x 50 mm DS18B20 probe, hanging tip-down on the inside of the PVC wall.
// The steel tip sits in a ventilated cage, standing off the wall, so it reads the air (not the
// wall) and the snake can't hook it. Drop the probe in from the top: the heat-shrink shoulder
// seats on a collar and a slotted clip grips the heat-shrink above it. Two screws from outside
// the PVC into 2.5 mm pilots (same depth as the IR pod bracket: M3 x 10-12, or #6 x 1/2" with
// the printed shims). Print standing upright, as modelled; no supports.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "mount";                 // "mount" | "check" (with a mock probe)
eps = 0.01;

// ---- parameters ----
probe_d = 6;  probe_l = 50;     // steel tip (listing)
shrink_d = 7.6;                 // heat-shrink just above the steel: MEASURE, sets the clip grip
grip = 0.3;                     // clip ID this much under shrink_d
cage_id = 11;  tube_t = 1.6;    // ventilated cage around the tip
slot_w = 4;  slot_n = 3;        // vertical windows (not on the wall side)
collar_t = 3;  collar_clr = 0.4;
clip_h = 14;  clip_gap = 4;     // slotted clip on the heat-shrink, opening to the front
tip_clear = 3;                  // cage extends past the tip
plate = [22, 7];                // width, thickness (screw plate against the wall)
pilot_d = 2.5;  pilot_depth = 6;  screw_inset = 6;

// ---- derived (Z up, wall face at Y = 0, probe axis at X = 0) ----
axis_y = plate.y + tube_t + cage_id/2;         // probe axis distance from the wall
cage_h = tip_clear + probe_l;                  // collar sits on top of the cage
collar_z = cage_h;
clip_z0 = collar_z + collar_t;
total_h = clip_z0 + clip_h;
clip_id = shrink_d - grip;
od = cage_id + 2*tube_t;
slot_h = cage_h - 2*tube_t - 3;
screw_z = [screw_inset, total_h - screw_inset];

// ---- asserts ----
assert(cage_id/2 - probe_d/2 >= 2, "tip too close to the cage");
assert(axis_y - probe_d/2 >= 10, "tip too close to the wall");
assert(pilot_depth < plate.y - 0.8, "pilot breaks through the plate");
assert(probe_d + 2*collar_clr < shrink_d - 0.6, "collar hole lets the heat-shrink through");
assert(clip_gap < clip_id - 1.5, "clip opening too wide to hold");
assert(slot_w <= 4, "slots wide enough for a snake to get into");

module mount() {
  difference() {
    union() {
      // screw plate
      translate([-plate.x/2, 0, 0]) cube([plate.x, plate.y + eps, total_h]);
      // cage + collar + clip as one tube
      translate([0, axis_y, 0]) cyl(d=od, h=total_h, anchor=BOT);
      // web tying the tube to the plate
      translate([-od/4, plate.y - eps, 0]) cube([od/2, axis_y - plate.y, total_h]);
    }
    translate([0, axis_y, 0]) {
      // cage bore, open at the bottom
      translate([0, 0, -eps]) cyl(d=cage_id, h=collar_z + eps, anchor=BOT);
      // collar hole, with a 45-degree cone under it so it prints without support
      cyl(d=probe_d + 2*collar_clr, h=3*total_h, anchor=CENTER);
      translate([0, 0, collar_z - (cage_id - probe_d)/2 + eps])
        cyl(d1=cage_id, d2=probe_d + 2*collar_clr, h=(cage_id - probe_d)/2 - collar_clr, anchor=BOT);
      // clip bore and its front opening
      translate([0, 0, clip_z0]) cyl(d=clip_id, h=clip_h + eps, anchor=BOT);
      translate([-clip_gap/2, 0, clip_z0]) cube([clip_gap, od, clip_h + eps]);
      // ventilation slots, spread over the front half
      for (i = [0:slot_n-1]) rotate([0, 0, -60 + i*60])
        translate([0, cage_id/2 - 0.5, tube_t + 3]) cuboid([slot_w, tube_t + 2, slot_h], anchor=BOT+FRONT);
    }
    // wall-screw pilots from the wall face
    for (z = screw_z) translate([0, -eps, z]) cyl(d=pilot_d, h=pilot_depth + eps, orient=BACK, anchor=BOT);
  }
}

if (part == "mount") mount();
else if (part == "check") {
  mount();
  translate([0, axis_y, tip_clear]) {
    color("Silver") cyl(d=probe_d, h=probe_l, anchor=BOT, rounding1=1);
    color("#222") translate([0, 0, probe_l]) cyl(d=shrink_d, h=30, anchor=BOT);
  }
}

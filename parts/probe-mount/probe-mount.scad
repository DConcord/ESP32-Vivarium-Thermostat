// Wall clip for a DS18B20 probe (5.85 x 33.6 mm steel tip, 6.4 x 16 mm sleeve), hanging tip-down
// on the inside of the PVC wall. The clip ring is the one that fit in the test print (6.3 mm bore,
// parts/test-prints/probe-clip-test): the steel passes through and the sleeve sits on top of the
// ring, so the tip hangs in open air below the clip, away from the wall. A mini zip tie through
// the slot above the ring, around the sleeve, stops the probe being pushed back up. Two screws from
// outside the PVC into 2.5 mm pilots (same depth as the IR pod bracket: M3 x 10-12, or #6 x 1/2"
// with the printed shims). Print standing upright, as modelled (clip ring on the bed); no supports.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "mount";                 // "mount" | "check" (with a mock probe)
eps = 0.01;

// ---- parameters ----
probe_d = 5.85;  probe_l = 33.6;               // steel tip (measured)
sleeve_d = 6.4;  sleeve_l = 16;                // black sleeve above the steel (measured)
clip_id = 6.3;  clip_od = 14.2;                // tested ring: passes the steel, seats the sleeve
clip_h = 12;  clip_gap = 3.5;                  // opening to the front, as tested
plate = [22, 7, 40];                           // width, thickness, height (against the wall)
web_w = 7;                                     // ties the ring and the tie anchor to the plate
tie_slot = [3, 1.8];                           // mini zip tie (2.5 mm wide), through the web
tie_z = clip_h + 6;                            // tie wraps the sleeve this high
pilot_d = 2.5;  pilot_depth = 6;
screw_z = [6, 34];

// ---- derived (Z up, wall face at Y = 0, probe axis at X = 0) ----
axis_y = plate.y + clip_od/2;                  // probe axis distance from the wall
web_y1 = axis_y - sleeve_d/2 - 0.5;            // web stops just short of the sleeve

// ---- asserts ----
assert(clip_id > probe_d && clip_id < sleeve_d + 0.2, "ring must pass the steel and stop the sleeve");
assert(clip_gap < probe_d - 1.5, "front opening lets the steel out");
assert(axis_y - probe_d/2 >= 8, "tip too close to the wall");
assert(pilot_depth < plate.y - 0.8, "pilot breaks through the plate");
assert(tie_z + tie_slot.y/2 < clip_h + sleeve_l - 2, "tie slot above the sleeve");
assert(max(screw_z) + 4 <= plate.z, "screw too close to the top");

module mount() {
  difference() {
    union() {
      // screw plate
      translate([-plate.x/2, 0, 0]) cube([plate.x, plate.y + eps, plate.z]);
      // clip ring, on the bed
      translate([0, axis_y, 0]) cyl(d=clip_od, h=clip_h, anchor=BOT);
      // web from the plate to the ring and up to the tie slot
      translate([-web_w/2, plate.y - eps, 0]) cube([web_w, web_y1 - plate.y + eps, tie_z + tie_slot.y/2 + 3]);
    }
    translate([0, axis_y, 0]) {
      // ring bore and front opening
      translate([0, 0, -eps]) cyl(d=clip_id, h=clip_h + 2*eps, anchor=BOT);
      translate([-clip_gap/2, 0, -eps]) cube([clip_gap, clip_od, clip_h + 2*eps]);
      // clearance for the sleeve above the ring, through the web
      translate([0, 0, clip_h]) cyl(d=sleeve_d + 1, h=plate.z, anchor=BOT);
    }
    // zip-tie slot through the web, side to side
    translate([0, (plate.y + web_y1)/2, tie_z]) cuboid([web_w + 2, tie_slot.x, tie_slot.y]);
    // wall-screw pilots from the wall face
    for (z = screw_z) translate([0, -eps, z]) cyl(d=pilot_d, h=pilot_depth + eps, orient=BACK, anchor=BOT);
  }
}

if (part == "mount") mount();
else if (part == "check") {
  mount();
  translate([0, axis_y, clip_h]) {
    color("Silver") cyl(d=probe_d, h=probe_l, anchor=TOP, rounding1=1);
    color("#222") cyl(d=sleeve_d, h=sleeve_l, anchor=BOT);
    color("#222") translate([0, 0, sleeve_l]) cyl(d=4.5, h=20, anchor=BOT);
  }
}

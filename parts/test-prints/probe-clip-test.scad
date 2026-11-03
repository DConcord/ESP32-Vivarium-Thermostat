// Fit test for the DS18B20 probe holster (../probe-mount/probe-mount.scad): just the collar and
// the heat-shrink clip, in three grip sizes, joined by a labelled bar. Drop the probe into each:
// the steel should pass the collar, the heat-shrink shoulder should stop on it, and the clip
// should hold the heat-shrink snugly. The label is the heat-shrink diameter it is sized for;
// the best one becomes shrink_d in probe-mount.scad. Print upright, as modelled; no supports.
include <../probe-mount/probe-mount.scad>
part = "none";                  // silences the holster itself

// ---- parameters ----
test_shrink_d = [7.2, 7.6, 8.0];  test_labels = ["7.2", "7.6", "8.0"];
             // heat-shrink diameters to try (holster default 7.6)
stub_h = 4;                                    // short piece of cage under the collar
bar_t = 2;  bar_w = 8;  label_h = 0.6;  label_size = 3.2;
spacing = od + 6;

// ---- derived ----
cone_h = (cage_id - probe_d)/2 - collar_clr;
test_h = stub_h + cone_h + collar_t + clip_h;
n_test = len(test_shrink_d);

// ---- asserts ----
assert(stub_h > 0, "need some cage under the collar");
assert(min(test_shrink_d) - grip > probe_d + 2*collar_clr, "smallest clip won't pass the steel");

module clip_test(sd) {
  difference() {
    cyl(d=od, h=test_h, anchor=BOT);
    // stub of cage bore, then the support cone under the collar
    translate([0, 0, -eps]) cyl(d=cage_id, h=stub_h + eps, anchor=BOT);
    translate([0, 0, stub_h - eps]) cyl(d1=cage_id, d2=probe_d + 2*collar_clr, h=cone_h + eps, anchor=BOT);
    cyl(d=probe_d + 2*collar_clr, h=3*test_h, anchor=CENTER);
    // clip bore and its front opening
    translate([0, 0, stub_h + cone_h + collar_t]) {
      cyl(d=sd - grip, h=clip_h + eps, anchor=BOT);
      translate([-clip_gap/2, 0, 0]) cube([clip_gap, od, clip_h + eps]);
    }
  }
}

union() {
  for (i = [0:n_test-1]) translate([i*spacing, 0, 0]) clip_test(test_shrink_d[i]);
  // joining bar behind the tubes, each size raised on its top face
  difference() {
    union() {
      translate([-od/2, -od/2 - bar_w + 1, 0]) cube([(n_test-1)*spacing + od, bar_w, bar_t]);
      for (i = [0:n_test-1]) translate([i*spacing, -od/2 - bar_w/2 + 0.5, bar_t - eps])
        linear_extrude(label_h + eps) text(test_labels[i], size=label_size, halign="center", valign="center");
    }
    for (i = [0:n_test-1]) translate([i*spacing, 0, -eps]) cyl(d=cage_id, h=bar_t + 1, anchor=BOT);
  }
}

// Fit test for the DS18B20 probe holster's sleeve clip (../probe-mount/probe-mount.scad), in
// three bore sizes on a labelled bar. Push the probe's steel tip through each from the top: it
// should slide through, and the 6.4 mm sleeve above it should then push in and be pinched
// snugly. The label is the bore; the best one becomes clip_id in probe-mount.scad.
// Print upright, as modelled; no supports.
include <../probe-mount/probe-mount.scad>
part = "none";                  // silences the holster itself

// ---- parameters ----
test_id = [6.0, 6.15, 6.3];  test_labels = ["6.0", "6.15", "6.3"];
bar_t = 2;  bar_w = 8;  label_h = 0.6;  label_size = 3;
spacing = od + 6;

// ---- derived ----
n_test = len(test_id);

// ---- asserts ----
for (d = test_id) assert(d > probe_d && d < sleeve_d, "test bore outside the steel/sleeve range");

module clip_test(id) {
  difference() {
    cyl(d=od, h=clip_h, anchor=BOT);
    translate([0, 0, -eps]) cyl(d=id, h=clip_h + 2*eps, anchor=BOT);
    translate([-clip_gap/2, 0, -eps]) cube([clip_gap, od, clip_h + 2*eps]);
  }
}

union() {
  for (i = [0:n_test-1]) translate([i*spacing, 0, 0]) clip_test(test_id[i]);
  // joining bar behind the clips, each bore raised on its top face
  difference() {
    union() {
      translate([-od/2, -od/2 - bar_w + 1, 0]) cube([(n_test-1)*spacing + od, bar_w, bar_t]);
      for (i = [0:n_test-1]) translate([i*spacing, -od/2 - bar_w/2 + 0.5, bar_t - eps])
        linear_extrude(label_h + eps) text(test_labels[i], size=label_size, halign="center", valign="center");
    }
    for (i = [0:n_test-1]) translate([i*spacing, 0, -eps]) cyl(d=test_id[i], h=bar_t + 1, anchor=BOT);
  }
}

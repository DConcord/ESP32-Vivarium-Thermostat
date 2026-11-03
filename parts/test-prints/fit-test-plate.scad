// Fit-test plate: the enclosure's wall features on one flat 3 mm plate, so they can be checked
// before printing the full box. Values copied from ../main-enclosure/main-enclosure.scad; keep in sync.
//   - switched inlet cutout + its two M3 self-tapping ear pilots (in pads on the inside face)
//   - 3/4" and 5/8" grommet keyholes (slot to the edge, wall thinned to the groove width)
//   - "lid strip": the lid's slot-closing tabs, slides into the slots from the edge
//   - screw samples: M3 pilot boss, M4 pilot boss (SSR), M3 heat-set insert boss (lid)
//   - OLED window + the slide-in holder rails behind it
// Print flat, outside face down. part = "plate" | "strip" | "both".
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "both";
eps = 0.01;

// ---- parameters (same as the enclosure) ----
wall = 3;
m3_insert_d = 4.0;  m3_insert_depth = 7.5;  boss_d = 9;
m3_pilot_d = 2.5;  m4_pilot_d = 3.4;
standoff_d = 8;  standoff_h = 9;  pb_pilot_depth = 7;              // M3 pilot (board standoffs)
ssr_boss_d = 10;  ssr_boss_h = 8;  ssr_pilot_depth = 9.5;  floor_t = 3;  // M4 pilot (SSR)
c14_cut = [28, 47.5];  c14_hole_pitch = 39.6;  c14_flange = [48.8, 59];
c14_pad_d = 9;  c14_pad_t = 6;  c14_pilot_depth = 7;
//   [hole d, flange d, slot w, label]
grommets = [[20.0, 24.0, 8, "3/4"], [15.9, 19.7, 6, "5/8"]];
grommet_panel_t = 1.8;  grommet_pocket_extra = 3;  lid_tab_clr = 0.3;
lid_t = 3;
oled_pcb = [35.4, 33.5, 1.6];  oled_glass_t = 1.2;
oled_win = [31, 19.5];  oled_view_top = 5;
oled_clr = 0.3;  rail_t = 2;  rail_lip = 2;

// ---- test-plate layout (X along the plate, Y up the "wall", rim = top edge) ----
plate = [168, 72];  corner_r = 3;  label_depth = 0.6;  label_size = 3.5;
c14_c = [35, 38];
g_cx = [78, 106];  g_rim_off = 20;            // hole centre this far below the rim (box: 44)
screw_y = 14;  screw_x = [70, 89, 108];
oled_cx = 143;  oled_ledge = [4, 4];          // ledge start Y and length
strip_gap = 8;                                // strip printed this far above the plate

// ---- derived ----
oled_groove = oled_glass_t + oled_pcb.z + 2*oled_clr;
oled_w = oled_pcb.x + 2*oled_clr;
oled_pcb_y0 = oled_ledge[0] + oled_ledge[1];  // PCB bottom edge
oled_rail_end = oled_pcb_y0 + oled_pcb.y + 1;
oled_win_cy = oled_pcb_y0 + oled_pcb.y - oled_view_top - oled_win.y/2;
g_cy = plate.y - g_rim_off;
strip_x = [g_cx[0] - 16, g_cx[1] + 14];

// ---- asserts ----
assert(c14_pilot_depth < wall + c14_pad_t - 1, "inlet pilot breaks through pad");
assert(c14_c.x - c14_flange.x/2 > 0 && c14_c.y - c14_flange.y/2 > 0 && c14_c.y + c14_flange.y/2 < plate.y, "inlet flange off the plate");
assert(c14_c.x + c14_hole_pitch/2 + c14_pad_d/2 < g_cx[0] - (grommets[0][1] + grommet_pocket_extra)/2, "inlet pad hits grommet pocket");
assert(g_cx[1] - g_cx[0] > (grommets[0][1] + grommets[1][1])/2 + grommet_pocket_extra, "grommet pockets overlap");
assert(g_cx[1] + (grommets[1][1] + grommet_pocket_extra)/2 < oled_cx - oled_w/2 - rail_t, "grommet pocket hits OLED rails");
assert(screw_y + ssr_boss_d/2 < g_cy - (grommets[0][1] + grommet_pocket_extra)/2, "screw bosses hit grommet pockets");
assert(oled_cx + oled_w/2 + rail_t < plate.x, "OLED rails off the plate");
assert(oled_rail_end < plate.y, "OLED rails off the plate");

module label(t, p) {
  translate([p.x, p.y, wall - label_depth]) linear_extrude(label_depth + eps)
    text(t, size=label_size, halign="center", valign="center");
}

module test_plate() {
  difference() {
    union() {
      cuboid([plate.x, plate.y, wall], rounding=corner_r, edges="Z", anchor=BOT+LEFT+FRONT);
      // inlet ear pads
      for (s=[-1,1]) translate([c14_c.x + s*c14_hole_pitch/2, c14_c.y, 0]) cyl(d=c14_pad_d, h=wall + c14_pad_t, anchor=BOT);
      // screw samples
      translate([screw_x[0], screw_y, 0]) cyl(d=standoff_d, h=wall + standoff_h, anchor=BOT);
      translate([screw_x[1], screw_y, 0]) cyl(d=ssr_boss_d, h=floor_t + ssr_boss_h, anchor=BOT);
      translate([screw_x[2], screw_y, 0]) cyl(d=boss_d, h=wall + standoff_h, anchor=BOT);
      // OLED holder: ledge + two L-rails (the PCB slides in from the open end)
      h = wall + oled_groove + rail_t;
      translate([oled_cx, 0, 0]) {
        translate([-oled_w/2 - rail_t, oled_ledge[0], 0]) cube([oled_w + 2*rail_t, oled_ledge[1], h]);
        for (s=[-1,1]) {
          translate([s*(oled_w/2 + rail_t/2) - rail_t/2, oled_ledge[0], 0]) cube([rail_t, oled_rail_end - oled_ledge[0], h]);
          translate([s > 0 ? oled_w/2 - rail_lip : -oled_w/2 - eps, oled_ledge[0], h - rail_t])
            cube([rail_lip + eps, oled_rail_end - oled_ledge[0], rail_t]);
        }
      }
    }
    // inlet cutout + pilots from the outside face
    translate([c14_c.x, c14_c.y, wall/2]) cube([c14_cut.x, c14_cut.y, 3*wall], center=true);
    for (s=[-1,1]) translate([c14_c.x + s*c14_hole_pitch/2, c14_c.y, -eps]) cyl(d=m3_pilot_d, h=c14_pilot_depth + eps, anchor=BOT);
    // grommet keyholes: hole + slot to the rim + thinning pocket from the inside face
    for (i = [0:1]) let(g = grommets[i]) translate([g_cx[i], 0, 0]) {
      translate([0, g_cy, -eps]) cyl(d=g[0], h=wall + 2*eps, anchor=BOT);
      translate([-g[2]/2, g_cy, -eps]) cube([g[2], plate.y, wall + 2*eps]);
      pocket_d = g[1] + grommet_pocket_extra;
      hull() for (y=[g_cy, plate.y + pocket_d/2])
        translate([0, y, grommet_panel_t]) cyl(d=pocket_d, h=wall, anchor=BOT);
      label(g[3], [0, g_cy - pocket_d/2 - 3]);
    }
    // screw pilots and insert hole
    translate([screw_x[0], screw_y, wall + standoff_h - pb_pilot_depth]) cyl(d=m3_pilot_d, h=pb_pilot_depth + eps, anchor=BOT);
    translate([screw_x[1], screw_y, floor_t + ssr_boss_h - ssr_pilot_depth]) cyl(d=m4_pilot_d, h=ssr_pilot_depth + eps, anchor=BOT);
    translate([screw_x[2], screw_y, wall + standoff_h - m3_insert_depth]) cyl(d=m3_insert_d, h=m3_insert_depth + eps, anchor=BOT);
    // OLED window, chamfered outward (wider on the outside face)
    translate([oled_cx, oled_win_cy, wall + eps]) prismoid(size1=oled_win, size2=oled_win + [2*wall, 2*wall], h=wall + 2*eps, anchor=BOT, orient=DOWN);
    // labels on the inside face
    label("M3", [screw_x[0], screw_y - 9]);
    label("M4", [screw_x[1], screw_y - 9]);
    label("INS", [screw_x[2], screw_y - 9]);
  }
}

// Lid stand-in: a bar that sits on the rim, with the tabs that close each slot (concave ends
// complete the round hole). Built in assembled position; slides into the slots from the rim.
module lid_strip() {
  translate([strip_x[0], plate.y, 0]) cube([strip_x[1] - strip_x[0], lid_t, wall]);
  for (i = [0:1]) let(g = grommets[i]) translate([g_cx[i], 0, 0]) difference() {
    translate([-g[2]/2 + lid_tab_clr, g_cy, 0]) cube([g[2] - 2*lid_tab_clr, plate.y - g_cy + eps, grommet_panel_t]);
    translate([0, g_cy, -eps]) cyl(d=g[0], h=grommet_panel_t + 2*eps, anchor=BOT);
  }
}

// print layout: strip flipped so its tabs point away from the plate
module strip_print() { translate([0, 2*plate.y + lid_t + strip_gap, 0]) mirror([0, 1, 0]) lid_strip(); }

if (part == "plate") test_plate();
else if (part == "strip") strip_print();
else if (part == "both") { test_plate(); strip_print(); }
else if (part == "assembled") { test_plate(); color("SteelBlue") lid_strip(); }

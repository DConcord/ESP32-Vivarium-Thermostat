// Main thermostat enclosure: base (mains bay + low-voltage bay) and lid.
// MOCKUP: component dimensions are typical values; verify against real parts.
// Frame: origin = outer back-left-bottom corner of the base, +Z up.
// -Y wall = BACK (inlet, outlet, cable grommets). +Y wall = FRONT (OLED window).
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "base";                  // "base" | "lid" | "assembly"
eps = 0.01;

// ---- parameters ----
wall = 3;  floor_t = 3;
mains_w = 90;                   // mains bay interior width (X)
div_t = 2;                      // divider thickness
lv_w = 92;                      // low-voltage bay interior width (X)
in_y = 90;  in_h = 45;          // interior depth (Y) and height (Z)
corner_r = 4;                   // outer vertical-edge rounding

boss_d = 9;                     // lid screw bosses in the 4 corners
// Kadrick heat-set inserts: M3 OD 4.5 / 3.9 tip, M4 OD 5.5 / 5.0 tip. Hole = tip + ~0.1, depth = length + 1.5
m3_insert_d = 4.0;  m3_insert_depth = 7.5;     // lid screws: M3 x 6 inserts
m3_clear = 3.4;  m3_head_d = 6.2;  m3_head_depth = 1.5;

// Inkbird SSR-40DA: 62.5 x 45 body, M4 holes 47.6 apart along the long axis
ssr_size = [62.5, 45];  ssr_hole_pitch = 47.6;
ssr_boss_d = 10;  ssr_boss_h = 8;  m4_insert_d = 5.1;  m4_insert_depth = 9.5;  // M4 x 8 inserts
ssr_center_y = 66;              // SSR sits in the back half of the mains bay

// C14 fused inlet (screw-ear type): panel cutout and ear holes
c14_cut = [28, 32];  c14_hole_pitch = 40;  c14_x = 31;
c14_pad_d = 9;  c14_pad_t = 5;  c14_insert_depth = 6.5; // inside pads, M3 x 5 inserts from outside
// NEMA 5-15R snap-in receptacle: cutout, and snap clips want a thin panel
outlet_cut = [27, 27];  outlet_panel_t = 1.6;  outlet_x = 73;
outlet_pocket = [34, 34];       // inside thinning pocket around the cutout

// Low-voltage bay
// Two rubber grommets (Vrupin kit, 3/4" = 19.05 mm mounting hole) in the back wall.
// Each hole has a slot up to the rim so pre-soldered cables drop in (slit the grommet);
// a lid tab with a concave bottom closes the slot so the grommet seats all the way round.
grommet_hole_d = 19.05;  grommet_flange_d = 25.4;  // flange OD (verify)
grommet_panel_t = 1.6;          // grommet groove width; wall is thinned to this (verify)
grommet_z = 19;  grommet_pitch = 36;  grommet_slot_w = 8;  // slot passes Cat6 (~6 mm)
grommet_pocket_d = grommet_flange_d + 3;
lid_tab_clr = 0.3;
pb_size = [84, 53];             // ElectroCookie full board (verify)
pb_hole_pitch = 73.7;           // 2 centerline mounting holes, ~29 rows x 2.54 (verify)
pb_center_y = 55;
standoff_d = 8.5;  standoff_h = 6;  pb_insert_depth = 6.5;  // M3 x 5 inserts
div_notch = [10, 8];            // wire pass-through at floor (Y width, Z height)

// Lid
lid_t = 3;  lip_h = 3;  lip_t = 1.6;  lip_clr = 0.2;
// SH1106 1.3" OLED on the FRONT wall. The PCB drops into open-top grooves behind the
// window (glass against the wall), rests on a ledge, and the lid lip keeps it down.
oled_pcb = [35.4, 33.5, 1.6];   // width (X), height (Z), thickness (verify)
oled_glass_t = 1.6;             // glass stack in front of the PCB (verify)
oled_win = [31, 17];  oled_win_dz = 1.5;  // window offset toward the header (up)
oled_z0 = 9;                    // PCB bottom edge height
oled_clr = 0.3;  rail_t = 2;  rail_lip = 2;

// ---- derived ----
in_x = mains_w + div_t + lv_w;
outer = [in_x + 2*wall, in_y + 2*wall, in_h + floor_t];
div_x = wall + mains_w;                       // divider left face
lv_x0 = div_x + div_t;                        // LV bay interior start
lv_cx = lv_x0 + lv_w/2;
mains_cx = wall + mains_w/2;
mid_z = floor_t + in_h/2;
boss_off = wall + boss_d/2 - 1;               // boss centers from outer edges
boss_pts = [for (x=[boss_off, outer.x-boss_off], y=[boss_off, outer.y-boss_off]) [x,y]];
oled_groove = oled_glass_t + oled_pcb.z + 2*oled_clr;   // depth behind the front wall
oled_w = oled_pcb.x + 2*oled_clr;
oled_y_in = outer.y - wall;                              // front wall inner face
oled_y_back = oled_y_in - oled_groove - rail_t;
oled_rail_top = oled_z0 + oled_pcb.y + 1;
oled_win_z = oled_z0 + oled_pcb.y/2 + oled_win_dz;

// ---- asserts ----
assert(wall >= 2.0, "mains enclosure wall too thin");
assert(floor_t + ssr_boss_h - m4_insert_depth >= 1.2, "SSR insert breaks through floor");
assert(c14_insert_depth < wall + c14_pad_t - 1, "C14 insert breaks through pad");
assert(standoff_d - 4.5 >= 3.5, "standoff wall too thin around insert");
assert(c14_x - c14_hole_pitch/2 - 4 > wall, "C14 ears hit left wall");
assert(outlet_x + outlet_pocket.x/2 < div_x, "outlet pocket crosses divider");
assert(c14_x + c14_hole_pitch/2 + 4 < outlet_x - outlet_pocket.x/2, "C14 and outlet overlap");
assert(mains_cx + ssr_size.x/2 < div_x && mains_cx - ssr_size.x/2 > wall, "SSR does not fit");
assert(grommet_pitch/2 + grommet_pocket_d/2 + boss_d < lv_w/2, "grommet pocket hits corner boss");
assert(grommet_pitch > grommet_pocket_d, "grommet pockets overlap");
assert(grommet_z - grommet_flange_d/2 > floor_t, "grommet flange hits floor");
assert(oled_rail_top <= outer.z - lip_h - 0.3, "OLED rails hit lid lip");
assert(pb_center_y + pb_size.y/2 < oled_y_back - 1, "protoboard hits OLED rails");
assert(pb_size.x < lv_w && pb_center_y + pb_size.y/2 < wall + in_y && pb_center_y - pb_size.y/2 > wall + 14, "protoboard does not fit");

// ---- geometry: base ----
module base() {
  difference() {
    union() {
      difference() {
        cuboid(outer, rounding=corner_r, edges="Z", anchor=BOT+LEFT+FRONT);
        translate([wall, wall, floor_t])
          cuboid([in_x, in_y, in_h+eps], rounding=1, edges="Z", anchor=BOT+LEFT+FRONT);
      }
      // corner bosses for lid screws
      for (p = boss_pts) translate([p.x, p.y, 0]) cyl(d=boss_d, h=outer.z, anchor=BOT);
      // divider
      translate([div_x, wall-eps, 0]) cube([div_t, in_y+2*eps, outer.z]);
      // SSR bosses
      for (s=[-1,1]) translate([mains_cx + s*ssr_hole_pitch/2, ssr_center_y, 0])
        cyl(d=ssr_boss_d, h=floor_t+ssr_boss_h, anchor=BOT);
      // protoboard standoffs
      for (sx=[-1,1]) translate([lv_cx + sx*pb_hole_pitch/2, pb_center_y, 0])
        cyl(d=standoff_d, h=floor_t+standoff_h, anchor=BOT);
      // C14 ear pads (inverted teardrop: no overhang underneath)
      for (s=[-1,1]) translate([c14_x + s*c14_hole_pitch/2, wall + c14_pad_t/2 - eps, mid_z])
        mirror([0,0,1]) teardrop(h=c14_pad_t + 2*eps, d=c14_pad_d);
      // OLED holder: ledge + two L-rails forming open-top grooves
      translate([lv_cx, 0, 0]) {
        translate([-oled_w/2 - rail_t, oled_y_back, 0])
          cube([oled_w + 2*rail_t, oled_y_in - oled_y_back + eps, oled_z0]);
        for (s=[-1,1]) {
          translate([s*(oled_w/2 + rail_t/2) - rail_t/2, oled_y_back, 0])
            cube([rail_t, oled_y_in - oled_y_back + eps, oled_rail_top]);
          translate([s > 0 ? oled_w/2 - rail_lip : -oled_w/2 - eps, oled_y_back, 0])
            cube([rail_lip + eps, rail_t, oled_rail_top]);
        }
      }
    }
    // lid screw inserts
    for (p = boss_pts) translate([p.x, p.y, outer.z - m3_insert_depth])
      cyl(d=m3_insert_d, h=m3_insert_depth+eps, anchor=BOT);
    // SSR inserts
    for (s=[-1,1]) translate([mains_cx + s*ssr_hole_pitch/2, ssr_center_y, floor_t+ssr_boss_h-m4_insert_depth])
      cyl(d=m4_insert_d, h=m4_insert_depth+eps, anchor=BOT);
    // protoboard inserts
    for (sx=[-1,1]) translate([lv_cx + sx*pb_hole_pitch/2, pb_center_y, floor_t+standoff_h-pb_insert_depth])
      cyl(d=m3_insert_d, h=pb_insert_depth+eps, anchor=BOT);
    // divider wire notch
    translate([div_x-eps, outer.y/2 - div_notch.x/2, floor_t-eps]) cube([div_t+2*eps, div_notch.x, div_notch.y]);
    // C14 inlet cutout + ear holes (-Y wall)
    translate([c14_x, wall/2, mid_z]) cube([c14_cut.x, wall+2*eps, c14_cut.y], center=true);
    for (s=[-1,1]) translate([c14_x + s*c14_hole_pitch/2, -eps, mid_z])
      cyl(d=m3_insert_d, h=c14_insert_depth+eps, orient=BACK, anchor=BOT);
    // outlet cutout + inside thinning pocket (-Y wall)
    translate([outlet_x, wall/2, mid_z]) cube([outlet_cut.x, wall+2*eps, outlet_cut.y], center=true);
    translate([outlet_x - outlet_pocket.x/2, outlet_panel_t, mid_z - outlet_pocket.y/2])
      cube([outlet_pocket.x, wall - outlet_panel_t + eps, outlet_pocket.y]);
    // grommet keyholes (back wall, LV bay): hole + slot to the rim + inside thinning pocket
    for (s=[-1,1]) translate([lv_cx + s*grommet_pitch/2, 0, 0]) {
      translate([0, -eps, grommet_z]) cyl(d=grommet_hole_d, h=wall + 2*eps, orient=BACK, anchor=BOT);
      translate([-grommet_slot_w/2, -eps, grommet_z]) cube([grommet_slot_w, wall + 2*eps, outer.z]);
      hull() for (z=[grommet_z, outer.z + grommet_pocket_d/2])
        translate([0, grommet_panel_t, z]) cyl(d=grommet_pocket_d, h=wall - grommet_panel_t + eps, orient=BACK, anchor=BOT);
    }
    // OLED window (front wall), chamfered outward
    translate([lv_cx, oled_y_in - eps, oled_win_z]) rotate([-90,0,0])
      prismoid(size1=oled_win, size2=oled_win + [2*wall, 2*wall], h=wall + 2*eps, anchor=BOT);
  }
}

// ---- geometry: lid (built in assembled position, plate on Z=0..lid_t, lip below) ----
module lid_assembled() {
  lip_out = [in_x - 2*lip_clr, in_y - 2*lip_clr];
  difference() {
    union() {
      cuboid([outer.x, outer.y, lid_t], rounding=corner_r, edges="Z", anchor=BOT+LEFT+FRONT);
      // locating lip
      translate([wall+lip_clr, wall+lip_clr, -lip_h]) difference() {
        cube([lip_out.x, lip_out.y, lip_h+eps]);
        translate([lip_t, lip_t, -eps]) cube([lip_out.x-2*lip_t, lip_out.y-2*lip_t, lip_h+3*eps]);
      }
      // tabs that close the grommet slots; concave bottom completes the round hole
      for (s=[-1,1]) translate([lv_cx + s*grommet_pitch/2, 0, 0]) difference() {
        translate([-grommet_slot_w/2 + lid_tab_clr, 0, grommet_z - outer.z])
          cube([grommet_slot_w - 2*lid_tab_clr, grommet_panel_t, outer.z - grommet_z + eps]);
        translate([0, -eps, grommet_z - outer.z]) cyl(d=grommet_hole_d, h=grommet_panel_t + 2*eps, orient=BACK, anchor=BOT);
      }
    }
    // lip clearance around bosses and divider
    for (p = boss_pts) translate([p.x, p.y, -lip_h-eps]) cyl(d=boss_d+0.8, h=lip_h+eps, anchor=BOT);
    translate([div_x - 0.3, 0, -lip_h-eps]) cube([div_t+0.6, outer.y, lip_h+eps]);
    // screw holes + counterbores
    for (p = boss_pts) translate([p.x, p.y, 0]) {
      cyl(d=m3_clear, h=3*lid_t, anchor=CENTER);
      translate([0,0,lid_t-m3_head_depth]) cyl(d=m3_head_d, h=m3_head_depth+eps, anchor=BOT);
    }
  }
}

// Print orientation: outside face down, lip up (flip about X)
module lid_print() {
  translate([0, outer.y, lid_t]) rotate([180,0,0]) lid_assembled();
}

if (part == "base") base();
else if (part == "lid") lid_print();
else if (part == "mockup") { base(); components(); color("SteelBlue", 0.25) translate([0, 0, outer.z]) lid_assembled(); }
else if (part == "mockup_open") { base(); components(); }
else if (part == "assembly") {
  base();
  color("SteelBlue", 0.6) translate([0, 0, outer.z + 15]) lid_assembled();
}

// ---- placeholder components for visual mockups (approximate shapes, not for printing) ----
module components() {
  ssr_z = floor_t + ssr_boss_h;
  // SSR-40DA
  color("Gainsboro") translate([mains_cx, ssr_center_y, ssr_z]) cuboid([ssr_size.x, ssr_size.y, 23], anchor=BOT);
  color("Silver") for (sx=[-1,1], sy=[-1,1]) translate([mains_cx + sx*20, ssr_center_y + sy*11, ssr_z + 23]) cyl(d=7, h=2, anchor=BOT);
  // C14 inlet: flange outside, body inside
  color("#222") translate([c14_x, 0, mid_z]) {
    translate([0, -3, 0]) cuboid([c14_hole_pitch + 8, 3, c14_cut.y + 2], rounding=2, edges="Y", anchor=FRONT);
    cuboid([c14_cut.x - 0.5, 27, c14_cut.y - 0.5], anchor=FRONT);
  }
  // power cord plug into the C14
  color("#333") translate([c14_x, -3, mid_z]) cuboid([24, 30, 20], rounding=3, anchor=BACK);
  // NEMA outlet: face flush outside, body inside
  color("#222") translate([outlet_x, 0, mid_z]) cuboid([outlet_cut.x - 0.5, 24, outlet_cut.y - 0.5], anchor=FRONT);
  color("#111") translate([outlet_x, -0.6, mid_z]) cuboid([outlet_cut.x + 2, 0.6, outlet_cut.y + 2], anchor=FRONT);
  // heat panel plug in the outlet
  color("#ddd") translate([outlet_x, -0.6, mid_z]) cuboid([22, 26, 24], rounding=3, anchor=BACK);
  // protoboard + ESP32 on female headers
  pb_z = floor_t + standoff_h;
  color("#111") translate([lv_cx, pb_center_y, pb_z]) cuboid([pb_size.x, pb_size.y, 1.6], rounding=3, edges="Z", anchor=BOT);
  color("#333") for (sy=[-1,1]) translate([lv_cx, pb_center_y + sy*12.7, pb_z + 1.6]) cuboid([48, 2.5, 8.5], anchor=BOT);
  color("#1a1a1a") translate([lv_cx, pb_center_y, pb_z + 10.1]) cuboid([55, 28, 1.6], anchor=BOT);
  color("Silver") translate([lv_cx + 14, pb_center_y, pb_z + 11.7]) cuboid([18, 25, 3], anchor=BOT);
  // OLED module in its grooves
  oy = oled_y_in - oled_glass_t - oled_clr;
  color("#1565c0") translate([lv_cx, oy, oled_z0]) cuboid([oled_pcb.x, oled_pcb.z, oled_pcb.y], anchor=BACK+BOT);
  color("#0b0b2a") translate([lv_cx, oy, oled_win_z]) cuboid([34.5, oled_glass_t, 23], anchor=FRONT);
  // grommets + cables
  for (s=[-1,1]) translate([lv_cx + s*grommet_pitch/2, 0, grommet_z]) {
    color("#151515") translate([0, grommet_panel_t/2, 0]) rotate([90,0,0]) difference() {
      union() {
        for (z=[-1,1]) translate([0,0,z*(grommet_panel_t/2 + 0.75)]) cyl(d=grommet_flange_d, h=1.5);
        cyl(d=grommet_hole_d, h=grommet_panel_t + eps);
      }
      cyl(d=12.7, h=10);
    }
  }
  cab = [[-1, [[-2.5, 1.5, 6.0, "#3a7bd5"], [3.5, -2, 3.5, "#111"]]],        // Cat6 + USB
         [ 1, [[-2.6, -1.5, 4.0, "#111"], [2.6, -1.5, 4.0, "#111"], [0, 2.6, 4.5, "#111"]]]]; // DS18B20 x2 + SHT30
  for (g = cab) for (c = g[1]) color(c[3])
    translate([lv_cx + g[0]*grommet_pitch/2 + c[0], -40, grommet_z + c[1]]) cyl(d=c[2], h=40 + 20, orient=BACK, anchor=BOT);
}

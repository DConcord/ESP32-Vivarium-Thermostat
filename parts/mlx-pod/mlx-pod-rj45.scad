// CONCEPT MOCK-UP (for discussion, not yet print-validated against real parts):
// IR pod v2, side-entry RJ45. The Cat6 plug goes into the SIDE of the pod (the side that faces
// the floor when the pod is aimed down), so the cable never runs into the yoke or bracket.
//
// Layout along the sensor axis (Z, front = lens = Z 0):
//   lens aperture -> GY-906 (lens tube forward, STRAIGHT header on its back, pointing rearward)
//   -> two rows of Dupont jumpers side by side -> RJ45 breakout lying flat across the back on
//   ledges, STRAIGHT header on its underside (pointing at the sensor), jack on top with its
//   mouth facing -Y out through a notch in the side wall. The cap closes the back and bears on
//   the jack, holding the board down.
//
// RJ45 board: Treedix RJ45 breakout, measured with calipers (header pin offset assumed 1.27).
// The pivot sits near the back so the yoke stays short. Pan + tilt joints keep the 15 deg teeth.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "assembly";              // "body" | "cap" | "yoke" | "bracket" | "assembly" | "cutaway" | "mount"
show_plug = true;               // preview: Cat6 plug in the jack
pan = 270;                      // preview: 270 = aimed straight out from the wall
tilt = 45;                      // preview: 0 = lens straight down (multiple of 15)
eps = 0.01;

// ---- GY-906-DCI (measured, from mlx-pod.scad; origin = PCB centre, +Y = pin edge) ----
pcb = [11.41, 16.86, 1.57];
tube_d = 9.05;  tube_h = 20.43;
gy_flip = true;                 // GY-906 turned 180 deg: its pins on the jack side (-Y), opposite
                                // the RJ45 header row, so the jumpers run diagonally across
gy_dir = gy_flip ? -1 : 1;
tube_xy = [0, gy_dir*(pcb.y/2 - 8.22)];
hole_d = 3.0;  hole_pitch = 6.35;  hole_from_end = 2.52;
hole_xy = [for (s=[-1,1]) [s*hole_pitch/2, gy_dir*(-pcb.y/2 + hole_from_end)]];
gy_pins = 4;  gy_pin_y = gy_dir*(pcb.y/2 - 1.27);

// ---- headers and Dupont jumpers ----
pitch = 2.54;  hdr_plastic = 2.5;  dupont_l = 14;
wire_room = 12;                 // turn space at the open end of each row of housings

// ---- RJ45 breakout: Treedix (measured) ----
rj_pcb = [20.33, 24.32, 1.57];  // width (X, along the header), depth jack-edge to header-edge (Y), thickness
rj_jack = [15.79, 21.16, 14.29];// jack shield: width (X, centred), length (Y, flared top), height above the board
rj_jack_overhang = 0.35;        // jack mouth past the board's port edge (3.61 + 21.08 - 24.32 = 0.37)
rj_solder = 1.17;               // solder joints/pins below the board (under the jack, inboard of the ledges)
rj_pins = 8;  rj_hdr_from_edge = 1.27;  // straight header, 8 pins across the full width, underside (ASSUMED offset)

// ---- RJ45 plug + Cat6 (preview only) ----
plug = [11.7, 21, 8.3];  boot_l = 12;  cable_d = 6;

// ---- body ----
wall = 2.4;  clr = 0.3;
front_t = 2;  lip_w = 1;  sleeve_t = 1.2;  ledge_w = 0.8;
post_d = 5;  m25_pilot_d = 2.1;  m25_pilot_depth = 6;
rib_w = 1.2;  rib_h = 3;        // ledges under the RJ45 board's X edges
corner_r = 2;
m3_insert_d = 4.0;  m3_pilot_d = 2.5;  m3_clear = 3.4;
piv_boss_d = 13;  piv_boss_l = 5;  piv_insert_depth = 5.5;
teeth_n = 24;  tooth_h = 0.7;  tilt_r = [2.6, 6.3];
cap_t = 2.4;
cap_tab = [8, 7];  cap_tab_h = 8;  cap_pilot_depth = 6.5;  cap_tab_x = 7;  // two tabs, +Y side
win_clr = 0.4;                  // clearance around the jack mouth in the side notch

// ---- yoke + bracket ----
ear_t = 3;  yoke_w = 16;  yoke_base_t = 6;  piv_margin = 1.5;
pan_r = [2.6, 7.5];  groove_clr = 0.2;
br_w = 24;  plate_t = 7;  plate_h = 34;  arm_t = 5;  gusset = 14;
wall_screw_pitch = 12;  wall_screw_y = 26;  wall_pilot_depth = 6;  pvc_t = 6;

// ---- derived ----
pocket_xy = [pcb.x + 2*clr, pcb.y + 2*clr];
under_xy = pocket_xy - [2*ledge_w, 2*ledge_w];
in_x = rj_pcb.x + 2*clr;
in_y = rj_pcb.y + rj_jack_overhang + 2*clr;
body_xy = [in_x + 2*wall, in_y + 2*wall];
z_pcb = front_t + tube_h;
z_gy_back = z_pcb + pcb.z;
z_gy_conn = z_gy_back + hdr_plastic + dupont_l;           // end of the GY-906 housings
// RJ45 board underside: its housings must leave wire_room in front, and clear the GY-906 row
z_rjb = max(z_gy_conn + wire_room, z_gy_back + wire_room + dupont_l + hdr_plastic);
z_top = z_rjb + rj_pcb.z + rj_jack.z;                     // = jack top = cap inner face
jack_mouth_y = -in_y/2 + clr;                             // mouth at the inner face of the -Y wall
rj_y0 = jack_mouth_y + rj_jack_overhang;                  // board's jack edge
rj_hdr_y = rj_y0 + rj_pcb.y - rj_hdr_from_edge;           // header row (along X)
piv_z = z_rjb - 2;                                        // pivot near the back: short yoke
body_span_x = body_xy.x + 2*piv_boss_l;
cap_hole_y = body_xy.y/2 + 2.5;
rear_len = z_top + cap_t - piv_z;
swing_r = norm([rear_len, body_xy.y/2 + cap_tab.y]);      // back corners incl. the cap tabs
ear_gap = body_span_x + 2*tooth_h;
ear_piv_h = yoke_base_t + swing_r + piv_margin;
yoke_reach = max(ear_gap/2 + ear_t, swing_r);
wall_gap = 45;                  // pan axis to the wall: room for the pod + plug when aimed out
arm_reach = max(yoke_reach + 3, wall_gap);  arm_l = arm_reach + 8;

// ---- asserts ----
assert(abs(rj_hdr_y - gy_pin_y) >= pitch + 0.5, "the two rows of housings collide");
assert(rj_jack.x + 2*win_clr < in_x, "jack wider than the cavity");
assert(pocket_xy.y < in_y, "GY-906 pocket deeper than the cavity");
assert(piv_insert_depth < wall + piv_boss_l - 0.5, "pivot insert breaks into the cavity");
assert(in_x/2 - rib_w > rj_jack.x/2 + 0.5, "ledges reach under the jack's solder joints");
assert(rj_y0 + rj_pcb.y - 5 < rj_hdr_y - pitch/2 - 0.5, "ledges run into the header strip");

module teeth(r, n = teeth_n, h = tooth_h) {
  a = 360 / n;  wi = 2 * r[0] * tan(a/2);
  for (i = [0:n-1]) rotate([0, 0, i*a])
    multmatrix([[0,0,1,r[0]], [1,0,0,0], [0,1,0,0]])
      linear_extrude(r[1] - r[0], scale=[r[1]/r[0], 1]) polygon([[-wi/2, 0], [wi/2, 0], [0, h]]);
}

// ---- body (printed front-down, open at the back) ----
module body() {
  difference() {
    union() {
      difference() {
        cuboid([body_xy.x, body_xy.y, z_top], rounding=corner_r, edges="Z", anchor=BOT);
        translate([0,0,front_t]) cuboid([under_xy.x, under_xy.y, z_pcb - front_t + eps], anchor=BOT);
        translate([0,0,z_pcb]) cuboid([pocket_xy.x, pocket_xy.y, pcb.z + eps], anchor=BOT);
        translate([0,0,z_gy_back]) cuboid([in_x, in_y, z_top - z_gy_back + eps], anchor=BOT);
      }
      translate([tube_xy.x, tube_xy.y, 0]) cyl(d=tube_d + 2*clr + 2*sleeve_t, h=z_pcb - 3, anchor=BOT);
      for (h = hole_xy) translate([h.x, h.y, 0]) cyl(d=post_d, h=z_pcb, anchor=BOT);
      // ledges under the RJ45 board's X edges (45 deg underside so they print without support)
      for (s=[-1,1]) translate([s*(in_x/2 - rib_w/2 + eps), rj_y0 + rj_pcb.y/2 - 2, z_rjb]) hull() {
        cuboid([rib_w, rj_pcb.y - 6, eps], anchor=TOP);
        translate([s*rib_w/2, 0, -rib_h - rib_w]) cuboid([eps, rj_pcb.y - 6, eps], anchor=TOP);
      }
      for (s=[-1,1]) translate([s*(body_xy.x/2 + piv_boss_l/2 - eps), 0, piv_z])
        mirror([0,0,1]) teardrop(h=piv_boss_l + 2*eps, d=piv_boss_d, spin=90);
      for (s=[-1,1]) translate([s*(body_span_x/2 - eps), 0, piv_z]) rotate([0, s*90, 0]) teeth(tilt_r);
      // two cap tabs on the +Y side (the -Y side has the jack notch)
      for (x = [-cap_tab_x, cap_tab_x]) translate([x, body_xy.y/2 - eps, z_top - cap_tab_h]) hull() {
        translate([0, cap_tab.y/2, 0]) cuboid([cap_tab.x, cap_tab.y + eps, cap_tab_h], anchor=BOT);
        translate([0, eps/2, -cap_tab.y - 1]) cuboid([cap_tab.x, eps, eps], anchor=BOT);
      }
    }
    translate([tube_xy.x, tube_xy.y, front_t]) cyl(d=tube_d + 2*clr, h=z_pcb, anchor=BOT);
    translate([tube_xy.x, tube_xy.y, -eps]) cyl(d=tube_d + 2*clr - 2*lip_w, h=front_t + 2*eps, anchor=BOT);
    for (h = hole_xy) translate([h.x, h.y, z_pcb - m25_pilot_depth]) cyl(d=m25_pilot_d, h=m25_pilot_depth + eps, anchor=BOT);
    // jack notch in the -Y wall, open at the back so the board + jack drop in from behind
    translate([0, -body_xy.y/2 - eps, z_rjb + rj_pcb.z - win_clr])
      cuboid([rj_jack.x + 2*win_clr, wall + clr + 2*eps, z_top], anchor=BOT+FRONT);
    for (s=[-1,1]) translate([s*(body_span_x/2 + eps), 0, piv_z]) cyl(d=m3_insert_d, h=2*piv_insert_depth, orient=RIGHT);
    for (x = [-cap_tab_x, cap_tab_x]) translate([x, cap_hole_y, z_top - cap_pilot_depth]) cyl(d=m3_pilot_d, h=cap_pilot_depth + eps, anchor=BOT);
  }
}

// ---- cap (printed plate-down): closes the back and the top of the jack notch ----
module cap() {
  difference() {
    union() {
      cuboid([body_xy.x, body_xy.y, cap_t], rounding=corner_r, edges="Z", anchor=BOT);
      for (x = [-cap_tab_x, cap_tab_x]) translate([x, body_xy.y/2 + cap_tab.y/2 - eps, 0]) cuboid([cap_tab.x, cap_tab.y + 2*eps, cap_t], anchor=BOT);
    }
    for (x = [-cap_tab_x, cap_tab_x]) translate([x, cap_hole_y, -eps]) cyl(d=m3_clear, h=cap_t + 2*eps, anchor=BOT);
  }
}

// ---- yoke + wall bracket (same style as mlx-pod.scad) ----
module yoke() {
  outer_x = ear_gap + 2*ear_t;
  difference() {
    union() {
      cuboid([outer_x, yoke_w, yoke_base_t], rounding=2, edges="Z", anchor=BOT);
      for (s=[-1,1]) translate([s*(ear_gap/2 + ear_t/2), 0, 0]) hull() {
        cuboid([ear_t, yoke_w, eps], anchor=BOT);
        translate([0,0,ear_piv_h]) cyl(d=yoke_w, h=ear_t, orient=RIGHT);
      }
      for (s=[-1,1]) translate([s*(ear_gap/2 + eps), 0, ear_piv_h]) rotate([0, -s*90, 0]) teeth(tilt_r);
    }
    translate([0,0,-eps]) teeth(pan_r, h = tooth_h + groove_clr);
    for (s=[-1,1]) translate([s*(ear_gap/2 + ear_t/2), 0, ear_piv_h]) cyl(d=m3_clear, h=ear_t + 2*eps, orient=RIGHT);
    translate([0,0,-eps]) cyl(d=m3_insert_d, h=yoke_base_t + 2*eps, anchor=BOT);
  }
}
module bracket() {
  translate([arm_reach, eps, br_w/2]) rotate([90, 0, 0]) difference() { teeth(pan_r); cyl(r=pan_r[0], h=10); }
  difference() {
    linear_extrude(br_w) polygon([[0, 0], [arm_l, 0], [arm_l, arm_t], [plate_t + gusset, arm_t],
      [plate_t, arm_t + gusset], [plate_t, arm_t + plate_h], [0, arm_t + plate_h]]);
    translate([arm_reach, arm_t/2, br_w/2]) cyl(d=m3_clear, h=arm_t + 2*eps, orient=BACK);
    for (s=[-1,1]) translate([-eps, wall_screw_y, br_w/2 + s*wall_screw_pitch/2])
      cyl(d=m3_pilot_d, h=wall_pilot_depth + eps, orient=RIGHT, anchor=BOT);
  }
}

// ---- mock parts (preview only) ----
module gy906() {
  color("#1f6f3a") translate([0,0,z_pcb]) cuboid([pcb.x, pcb.y, pcb.z], anchor=BOT);
  color("Silver") translate([tube_xy.x, tube_xy.y, z_pcb - tube_h]) cyl(d=tube_d, h=tube_h, anchor=BOT);
  for (i = [0:gy_pins-1]) let(x = (i - (gy_pins-1)/2)*pitch) translate([x, gy_pin_y, z_gy_back]) {
    color("#222") cuboid([pitch, pitch, hdr_plastic], anchor=BOT);
    color(["Red","Black","White","Yellow"][i]) translate([0,0,hdr_plastic]) cuboid([pitch, pitch, dupont_l], anchor=BOT);
  }
}
module rj45_board() {
  color("#1e3a8a") translate([0, rj_y0, z_rjb]) cuboid([rj_pcb.x, rj_pcb.y, rj_pcb.z], anchor=BOT+FRONT);
  color("#d9d9d9") translate([0, jack_mouth_y, z_rjb + rj_pcb.z]) cuboid([rj_jack.x, rj_jack.y, rj_jack.z], anchor=BOT+FRONT);
  for (i = [0:rj_pins-1]) let(x = (i - (rj_pins-1)/2)*pitch, pin = i + 1, k = search(pin, [2,3,4,6])) translate([x, rj_hdr_y, z_rjb]) {
    color("#222") cuboid([pitch, pitch, hdr_plastic], anchor=TOP);
    if (k != []) color(["White","Black","Red","Yellow"][k[0]]) translate([0,0,-hdr_plastic]) cuboid([pitch, pitch, dupont_l], anchor=TOP);
  }
}
module plug_cable() {
  pz = z_rjb + rj_pcb.z + rj_jack.z/2;
  color("LightSkyBlue", 0.8) translate([0, jack_mouth_y + 15, pz]) cuboid(plug, anchor=BACK);
  translate([0, jack_mouth_y + 15 - plug.y, pz]) rotate([90,0,0]) {
    color("RoyalBlue") cyl(d1=9, d2=cable_d, h=boot_l, anchor=BOT);
    color("RoyalBlue") translate([0,0,boot_l]) cyl(d=cable_d, h=30, anchor=BOT);
  }
}
module assembled(cut=false) {
  difference() {
    union() {
      color("DimGray") body();
      color("SlateGray") translate([0,0,z_top + cap_t]) mirror([0,0,1]) cap();
    }
    if (cut) translate([0, -100, -50]) cube([100, 200, 300]);
  }
  gy906(); rj45_board(); if (show_plug) plug_cable();
}
// Mounted: PVC wall at x = 0, bracket arm out along +X, yoke below the arm (pan about vertical),
// pod hanging in the yoke. pan = 270 turns the yoke so the pod tilts away from the wall; the jack
// (-Y side) then faces down and back toward the wall.
module mount() {
  rotate([90,0,0]) bracket();
  color("Gray", 0.3) translate([-pvc_t, -br_w - 60, -140]) cube([pvc_t, br_w + 120, arm_t + plate_h + 150]);
  translate([arm_reach, -br_w/2, 0]) rotate([0, 0, pan]) {
    color("SteelBlue") rotate([180,0,0]) yoke();
    translate([0, 0, -ear_piv_h]) rotate([tilt,0,0]) translate([0, 0, -piv_z]) assembled();
  }
}

if (part == "body") body();
else if (part == "cap") cap();
else if (part == "yoke") yoke();
else if (part == "bracket") bracket();
else if (part == "assembly") assembled();
else if (part == "cutaway") assembled(cut=true);
else if (part == "mount") mount();
echo(str("POD outer: ", body_xy.x, " x ", body_xy.y, " x ", z_top + cap_t, " mm; pivot z=", piv_z,
  "; yoke pivot height ", ear_piv_h, "; arm reach ", arm_reach));

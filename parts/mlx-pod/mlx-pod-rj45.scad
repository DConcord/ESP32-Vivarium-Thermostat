// CONCEPT MOCK-UP (for discussion, not yet print-validated against real parts):
// IR pod v2 with the RJ45 jack inside the pod, so the Cat6 cable plugs straight into the
// back of the pod and the GY-906 connects to the jack board with Dupont jumpers.
//
// Layout along the sensor axis (Z, front = lens = Z 0):
//   lens aperture -> GY-906 (lens tube forward, straight header on its back)
//   -> Dupont jumpers -> RJ45 breakout board standing on edge in side grooves, jack mouth flush
//   with the rear cap. Both boards use STRAIGHT headers: the GY-906's points back along the axis;
//   the RJ45 board's sits on the jack side along its front edge, so its Dupont housings stand
//   up beside (in front of) the jack. That sets the pod's depth (Y).
// The Cat6 plug goes in from outside through the cap; its latch stays outside so it can be
// unplugged without opening the pod.
//
// RJ45 BOARD DIMENSIONS ARE PLACEHOLDERS: measure the real board (rj_* below) before printing.
// Pivot bosses and tilt teeth match mlx-pod.scad, so the same yoke style works; the yoke and
// bracket need regenerating for the wider body (not modelled here yet).
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "assembly";              // "body" | "cap" | "assembly" | "cutaway"
show_plug = true;               // preview: Cat6 plug in the jack
eps = 0.01;

// ---- GY-906-DCI (measured, from mlx-pod.scad; origin = PCB centre, +Y = pin edge) ----
pcb = [11.41, 16.86, 1.57];
tube_d = 9.05;  tube_h = 20.43;
tube_xy = [0, pcb.y/2 - 8.22];
hole_d = 3.0;  hole_pitch = 6.35;  hole_from_end = 2.52;
hole_xy = [for (s=[-1,1]) [s*hole_pitch/2, -pcb.y/2 + hole_from_end]];
gy_pins = 4;  gy_pin_y = pcb.y/2 - 1.27;     // header row along the pin edge

// ---- headers and Dupont jumpers ----
pitch = 2.54;
hdr_plastic = 2.5;              // header plastic strip height
dupont = [2.54, 2.54, 14];      // female Dupont housing (per pin)
slack = 6;                      // gap between the GY-906 housings and the RJ45 header row
wire_bend = 4;                  // room above the RJ45-side housings for the wires to turn

// ---- RJ45 breakout (PLACEHOLDERS: measure yours) ----
rj_pcb = [22, 26, 1.6];         // width (X), length jack-edge to header-edge (Z), thickness
rj_jack = [16, 13.5, 18];       // jack body: width (X), height above PCB (Y), depth (Z)
rj_jack_overhang = 1;           // jack mouth past the board's rear edge
rj_pins = 8;                    // straight header across the front edge, on the jack side
rj_hdr_from_edge = 1.27;        // header row centre from the board's front edge

// ---- RJ45 plug + Cat6 (preview only) ----
plug = [11.7, 8.3, 21];  boot_l = 12;  cable_d = 6;

// ---- body ----
wall = 2.4;  clr = 0.3;
front_t = 2;  lip_w = 1;  sleeve_t = 1.2;  ledge_w = 0.8;
post_d = 5;  m25_pilot_d = 2.1;  m25_pilot_depth = 6;
groove_d = 1.0;                 // board edges sit this deep in the side walls
corner_r = 2;
m3_insert_d = 4.0;  m3_pilot_d = 2.5;  m3_clear = 3.4;
piv_boss_d = 13;  piv_boss_l = 5;  piv_insert_depth = 5.5;
teeth_n = 24;  tooth_h = 0.7;  tilt_r = [2.6, 6.3];
cap_t = 2.4;
cap_tab = [9, 7];  cap_tab_h = 8;  cap_pilot_depth = 6.5;
jack_win_clr = 0.4;             // clearance around the jack face in the cap

// ---- derived ----
pocket_xy = [pcb.x + 2*clr, pcb.y + 2*clr];
under_xy = pocket_xy - [2*ledge_w, 2*ledge_w];
in_x = rj_pcb.x - 2*groove_d + 2*clr;           // cavity width between the grooves
rj_hdr_h = rj_pcb.z + hdr_plastic + dupont.z;    // board back face to the top of its housings
// Cavity depth: the board sits 0.6 off the -Y wall; its housings plus wire_bend must fit.
in_y = max(pocket_xy.y, 0.6 + rj_hdr_h + wire_bend);
body_xy = [in_x + 2*wall, in_y + 2*wall];
z_pcb = front_t + tube_h;                        // GY-906 front face
z_gy_back = z_pcb + pcb.z;
z_gy_conn_end = z_gy_back + hdr_plastic + dupont.z;
z_rj0 = z_gy_conn_end + slack;                   // RJ45 board front (header) edge
z_rj1 = z_rj0 + rj_pcb.y;                        // board rear edge
z_top = z_rj1 + rj_jack_overhang;                // = jack mouth = cap inner face
rj_y0 = -in_y/2 + 0.6;                           // board's -Y face
jack_y0 = rj_y0 + rj_pcb.z;                      // jack sits on the board's +Y face
piv_z = z_top/2;
body_span_x = body_xy.x + 2*piv_boss_l;
cap_hole_y = body_xy.y/2 + 2.5;

// ---- asserts ----
assert(wall - groove_d - clr >= 1.0, "groove leaves the side wall too thin");
assert(jack_y0 + rj_jack.y < in_y/2 - 0.3, "jack taller than the cavity");
assert(rj_y0 + rj_hdr_h + wire_bend <= in_y/2 + 0.01, "no room above the RJ45 housings for the wires");
assert(z_rj0 + rj_hdr_from_edge + pitch/2 < z_top - rj_jack.z, "header row runs into the jack");
assert(rj_jack.x < in_x, "jack wider than the cavity");
assert((rj_pins - 1)*pitch + pitch < in_x, "RJ45 header wider than the cavity");
assert(pocket_xy.x < in_x, "GY-906 pocket wider than the cavity");
assert(piv_insert_depth < wall + piv_boss_l - 0.5, "pivot insert breaks into the cavity");

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
        // under the GY-906: room for the tube and the posts
        translate([0,0,front_t]) cuboid([under_xy.x, under_xy.y, z_pcb - front_t + eps], anchor=BOT);
        // GY-906 locating pocket (its edges rest on the ledge)
        translate([0,0,z_pcb]) cuboid([pocket_xy.x, pocket_xy.y, pcb.z + eps], anchor=BOT);
        // main cavity behind the GY-906: jumpers + RJ45 board
        translate([0,0,z_gy_back]) cuboid([in_x, in_y, z_top - z_gy_back + eps], anchor=BOT);
      }
      translate([tube_xy.x, tube_xy.y, 0]) cyl(d=tube_d + 2*clr + 2*sleeve_t, h=z_pcb - 3, anchor=BOT);
      for (h = hole_xy) translate([h.x, h.y, 0]) cyl(d=post_d, h=z_pcb, anchor=BOT);
      // pivot bosses (teardrop underside) and tilt teeth, as in mlx-pod.scad
      for (s=[-1,1]) translate([s*(body_xy.x/2 + piv_boss_l/2 - eps), 0, piv_z])
        mirror([0,0,1]) teardrop(h=piv_boss_l + 2*eps, d=piv_boss_d, spin=90);
      for (s=[-1,1]) translate([s*(body_span_x/2 - eps), 0, piv_z]) rotate([0, s*90, 0]) teeth(tilt_r);
      // cap screw tabs at the back, with a support-free wedge underneath
      for (s=[-1,1]) translate([0, s*(body_xy.y/2 - eps), z_top - cap_tab_h]) hull() {
        translate([0, s*cap_tab.y/2, 0]) cuboid([cap_tab.x, cap_tab.y + eps, cap_tab_h], anchor=BOT);
        translate([0, s*eps/2, -cap_tab.y - 1]) cuboid([cap_tab.x, eps, eps], anchor=BOT);
      }
    }
    // lens bore and front aperture
    translate([tube_xy.x, tube_xy.y, front_t]) cyl(d=tube_d + 2*clr, h=z_pcb, anchor=BOT);
    translate([tube_xy.x, tube_xy.y, -eps]) cyl(d=tube_d + 2*clr - 2*lip_w, h=front_t + 2*eps, anchor=BOT);
    for (h = hole_xy) translate([h.x, h.y, z_pcb - m25_pilot_depth]) cyl(d=m25_pilot_d, h=m25_pilot_depth + eps, anchor=BOT);
    // RJ45 board grooves in the side walls: the board slides in from the back and stops at z_rj0
    for (s=[-1,1]) translate([s*(in_x/2 + (groove_d + clr)/2 - eps), rj_y0 + rj_pcb.z/2, z_rj0])
      cuboid([groove_d + clr + 2*eps, rj_pcb.z + 2*clr, z_top - z_rj0 + eps], anchor=BOT);
    // inserts
    for (s=[-1,1]) translate([s*(body_span_x/2 + eps), 0, piv_z]) cyl(d=m3_insert_d, h=2*piv_insert_depth, orient=RIGHT);
    for (s=[-1,1]) translate([0, s*cap_hole_y, z_top - cap_pilot_depth]) cyl(d=m3_pilot_d, h=cap_pilot_depth + eps, anchor=BOT);
  }
}

// ---- cap (printed plate-down): window for the jack mouth. Located by its two screw tabs; its
// inner face bears on the jack, holding the board against the groove stops. No locating lip:
// a lip would hit the board's rear edge.
module cap() {
  win = [rj_jack.x + 2*jack_win_clr, rj_jack.y + 2*jack_win_clr];
  win_y = jack_y0 + rj_jack.y/2;                 // jack centre, in body coordinates
  difference() {
    union() {
      cuboid([body_xy.x, body_xy.y, cap_t], rounding=corner_r, edges="Z", anchor=BOT);
      for (s=[-1,1]) translate([0, s*(body_xy.y/2 + cap_tab.y/2 - eps), 0]) cuboid([cap_tab.x, cap_tab.y + 2*eps, cap_t], anchor=BOT);
    }
    // cap is drawn plate-down with +Y flipped in use, so the window sits at -win_y here
    translate([0, -win_y, -eps]) cuboid([win.x, win.y, cap_t + 2*eps], anchor=BOT);
    for (s=[-1,1]) translate([0, s*cap_hole_y, -eps]) cyl(d=m3_clear, h=cap_t + 2*eps, anchor=BOT);
  }
}

// ---- mock parts (preview only) ----
module gy906() {
  color("#1f6f3a") translate([0,0,z_pcb]) cuboid([pcb.x, pcb.y, pcb.z], anchor=BOT);
  color("Silver") translate([tube_xy.x, tube_xy.y, z_pcb - tube_h]) cyl(d=tube_d, h=tube_h, anchor=BOT);
  for (i = [0:gy_pins-1]) let(x = (i - (gy_pins-1)/2)*pitch) translate([x, gy_pin_y, z_gy_back]) {
    color("#222") cuboid([pitch, pitch, hdr_plastic], anchor=BOT);
    color(["Red","Black","Yellow","White"][i]) translate([0,0,hdr_plastic]) cuboid(dupont, anchor=BOT);
  }
}
module rj45_board() {
  color("#1e3a8a") translate([0, rj_y0, z_rj0]) cuboid([rj_pcb.x, rj_pcb.z, rj_pcb.y], anchor=BOT+FRONT);
  color("#d9d9d9") translate([0, jack_y0, z_top - rj_jack.z]) cuboid([rj_jack.x, rj_jack.y, rj_jack.z], anchor=BOT+FRONT);
  for (i = [0:rj_pins-1]) let(x = (i - (rj_pins-1)/2)*pitch) translate([x, jack_y0, z_rj0 + rj_hdr_from_edge]) {
    color("#222") cuboid([pitch, hdr_plastic, pitch], anchor=FRONT);
    if (search(i+1, [2,3,4,6]) != []) color(["Yellow","Black","Red","White"][search(i+1,[2,3,4,6])[0]])
      translate([0, hdr_plastic, 0]) cuboid([dupont.x, dupont.z, dupont.y], anchor=FRONT);
  }
}
module plug_cable() {
  py = jack_y0 + rj_jack.y/2;
  color("LightSkyBlue", 0.8) translate([0, py, z_top - plug.z + 6]) cuboid(plug, anchor=BOT);
  color("RoyalBlue") translate([0, py, z_top + 6]) cyl(d1=9, d2=cable_d, h=boot_l, anchor=BOT);
  color("RoyalBlue") translate([0, py, z_top + 6 + boot_l]) cyl(d=cable_d, h=30, anchor=BOT);
}
module assembled(cut=false) {
  difference() {
    union() {
      color("DimGray") body();
      color("SlateGray") translate([0,0,z_top + cap_t]) mirror([0,0,1]) mirror([0,1,0]) cap();
    }
    if (cut) translate([0, -100, -50]) cube([100, 200, 300]);
  }
  gy906(); rj45_board(); if (show_plug) plug_cable();
}

if (part == "body") body();
else if (part == "cap") cap();
else if (part == "assembly") assembled();
else if (part == "cutaway") assembled(cut=true);
echo(str("POD outer: ", body_xy.x, " x ", body_xy.y, " x ", z_top + cap_t, " mm; pivot at z=", piv_z));

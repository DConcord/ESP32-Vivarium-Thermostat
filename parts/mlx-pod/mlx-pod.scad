// GY-906-DCI (MLX90614) sensor pod with tilt yoke and pan edge clip.
// MOCKUP: GY-906-DCI dimensions are estimates from photos; measure and update.
// Parts: body (front-down), cap, yoke (base-down), clip (on its side).
// Assembly: clip grips a panel edge -> M3 pan screw -> yoke -> 2x M3 tilt screws -> body.
// Kadrick M3 heat-set inserts (OD 4.5, tip 3.9): hole 4.0, depth = length + 1.5.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "body";                  // "body" | "cap" | "yoke" | "clip"
eps = 0.01;

// ---- parameters: sensor module (local PCB coords, origin = PCB center) ----
pcb = [16, 20, 1.6];            // X width, Y length, thickness (verify)
tube_d = 9.5;  tube_h = 20;     // black lens tube (verify)
tube_xy = [-2.5, 4];            // tube center on PCB (verify)
pcb_hole_xy = [5, 6];  pcb_hole_d = 3;  // PCB mounting hole beside tube (verify)

// ---- parameters: body ----
wall = 2;  clr = 0.3;
front_t = 2;  lip_w = 1;        // front plate; lip that stops the tube
sleeve_t = 1.6;                 // locating sleeve around the tube
ledge_w = 1;                    // PCB rests on this ledge
wire_h = 12;                    // space above PCB for header wires + 100 nF cap
post_d = 4.5;  m2_pilot_d = 1.7;
m3_insert_d = 4.0;
piv_boss_d = 9;  piv_boss_l = 5;  piv_insert_depth = 5.5;  // M3 x 4 inserts
cap_tab = [9, 7];  cap_tab_h = 8;  cap_insert_depth = 6.5;   // M3 x 5 inserts, tabs on +/-Y
corner_r = 2;

// ---- parameters: cap ----
cap_t = 2;  cap_lip_h = 3;  cap_lip_t = 1.2;  cap_clr = 0.2;
cable_d = 6.5;                  // Cat6 jacket pass-through

// ---- parameters: yoke ----
ear_t = 3;  yoke_w = 16;  yoke_base_t = 6;  washer_gap = 0.5;  // pan: M3 x 5 insert, through
m3_clear = 3.4;
piv_margin = 1.5;               // clearance between swinging pod and yoke base

// ---- parameters: clip ----
panel_t = 6;                    // thickness of the edge it clips onto (verify)
clip_w = 20;  jaw_t = 4;  spine_t = 4;
lower_jaw_l = 34;  upper_jaw_l = 18;
pan_hole_x = 24;  grip_hole_x = 12;

// ---- derived ----
body_xy = [pcb.x + 2*(clr+wall), pcb.y + 2*(clr+wall)];
z_pcb = front_t + tube_h;               // PCB underside rests here
z_top = z_pcb + pcb.z + wire_h;
pocket_xy = [pcb.x + 2*clr, pcb.y + 2*clr];
under_xy = pocket_xy - [2*ledge_w, 2*ledge_w];
piv_z = z_top/2;
body_span_x = body_xy.x + 2*piv_boss_l;
swing_r = norm([z_top/2, body_xy.y/2 + cap_tab.y]);  // pod corner (incl. cap tabs) about the pivot
cap_hole_y = body_xy.y/2 + 2.5;
ear_gap = body_span_x + 2*washer_gap;
ear_piv_h = yoke_base_t + swing_r + piv_margin;
ear_h = ear_piv_h + yoke_w/2;

// ---- asserts ----
assert(wall >= 1.2);
assert(pcb_hole_xy.x + post_d/2 <= under_xy.x/2 + wall, "PCB post outside body");
assert(norm(tube_xy - pcb_hole_xy) > tube_d/2 + pcb_hole_d/2, "PCB hole overlaps tube");
assert(piv_insert_depth < wall + piv_boss_l - 0.5, "pivot insert breaks into cavity");
assert(cap_tab.y - (cap_hole_y - body_xy.y/2) - 4.5/2 >= 1.2, "cap tab wall too thin");
assert(jaw_t >= 4, "jaw too thin for M3 x 4 insert");
assert(pan_hole_x > spine_t + yoke_w/2, "yoke hits clip spine");

// ---- body ----
module body() {
  difference() {
    union() {
      difference() {
        cuboid([body_xy.x, body_xy.y, z_top], rounding=corner_r, edges="Z", anchor=BOT);
        // cavity under the PCB
        translate([0,0,front_t]) cuboid([under_xy.x, under_xy.y, z_pcb-front_t+eps], anchor=BOT);
        // PCB pocket + wiring space
        translate([0,0,z_pcb]) cuboid([pocket_xy.x, pocket_xy.y, z_top-z_pcb+eps], anchor=BOT);
      }
      // tube sleeve and PCB screw post
      translate([tube_xy.x, tube_xy.y, 0]) cyl(d=tube_d + 2*clr + 2*sleeve_t, h=z_pcb - 3, anchor=BOT);
      translate([pcb_hole_xy.x, pcb_hole_xy.y, 0]) cyl(d=post_d, h=z_pcb, anchor=BOT);
      // pivot bosses (inverted teardrop so the underside prints without support)
      for (s=[-1,1]) translate([s*(body_xy.x/2 + piv_boss_l/2 - eps), 0, piv_z])
        mirror([0,0,1]) teardrop(h=piv_boss_l + 2*eps, d=piv_boss_d, spin=90);  // point down: solid boss
      // cap screw tabs, with a >45 deg wedge underneath so they print without support
      for (s=[-1,1]) translate([0, s*(body_xy.y/2 - eps), z_top - cap_tab_h]) hull() {
        translate([0, s*cap_tab.y/2, 0]) cuboid([cap_tab.x, cap_tab.y + eps, cap_tab_h], anchor=BOT);
        translate([0, s*eps/2, -cap_tab.y - 1]) cuboid([cap_tab.x, eps, eps], anchor=BOT);
      }
    }
    // tube bore and front aperture
    translate([tube_xy.x, tube_xy.y, front_t]) cyl(d=tube_d + 2*clr, h=z_pcb, anchor=BOT);
    translate([tube_xy.x, tube_xy.y, -eps]) cyl(d=tube_d + 2*clr - 2*lip_w, h=front_t + 2*eps, anchor=BOT);
    // M2 pilot in post
    translate([pcb_hole_xy.x, pcb_hole_xy.y, z_pcb - 6]) cyl(d=m2_pilot_d, h=6+eps, anchor=BOT);
    // M3 inserts in pivot bosses
    for (s=[-1,1]) translate([s*(body_span_x/2 + eps), 0, piv_z])
      cyl(d=m3_insert_d, h=2*piv_insert_depth, orient=RIGHT);
    // M3 inserts in cap tabs
    for (s=[-1,1]) translate([0, s*cap_hole_y, z_top - cap_insert_depth])
      cyl(d=m3_insert_d, h=cap_insert_depth + eps, anchor=BOT);
  }
}

// ---- cap (printed plate-down, lip up) ----
module cap() {
  lip_out = pocket_xy - [2*cap_clr, 2*cap_clr];
  difference() {
    union() {
      cuboid([body_xy.x, body_xy.y, cap_t], rounding=corner_r, edges="Z", anchor=BOT);
      for (s=[-1,1]) translate([0, s*(body_xy.y/2 + cap_tab.y/2 - eps), 0])
        cuboid([cap_tab.x, cap_tab.y + 2*eps, cap_t], anchor=BOT);
      translate([0,0,cap_t - eps]) difference() {
        cuboid([lip_out.x, lip_out.y, cap_lip_h + eps], anchor=BOT);
        translate([0,0,-eps]) cuboid([lip_out.x - 2*cap_lip_t, lip_out.y - 2*cap_lip_t, cap_lip_h + 3*eps], anchor=BOT);
      }
    }
    translate([0,0,-eps]) cyl(d=cable_d, h=cap_t + 2*eps, anchor=BOT);
    for (s=[-1,1]) translate([0, s*cap_hole_y, -eps]) cyl(d=m3_clear, h=cap_t + 2*eps, anchor=BOT);
  }
}

// ---- yoke (base down, ears up; inverted in use) ----
module yoke() {
  outer_x = ear_gap + 2*ear_t;
  difference() {
    union() {
      cuboid([outer_x, yoke_w, yoke_base_t], rounding=2, edges="Z", anchor=BOT);
      for (s=[-1,1]) translate([s*(ear_gap/2 + ear_t/2), 0, 0])
        hull() {
          cuboid([ear_t, yoke_w, eps], anchor=BOT);
          translate([0,0,ear_piv_h]) cyl(d=yoke_w, h=ear_t, orient=RIGHT);
        }
    }
    // tilt screw holes
    for (s=[-1,1]) translate([s*(ear_gap/2 + ear_t/2), 0, ear_piv_h]) cyl(d=m3_clear, h=ear_t + 2*eps, orient=RIGHT);
    // pan insert (M3 x 5, through; press in from the clip side = print bed face)
    translate([0,0,-eps]) cyl(d=m3_insert_d, h=yoke_base_t + 2*eps, anchor=BOT);
  }
}

// ---- edge clip: C profile in XY, extruded along Z (printed on its side) ----
module clip() {
  difference() {
    union() {
      cube([spine_t, 2*jaw_t + panel_t, clip_w]);                  // spine
      cube([lower_jaw_l, jaw_t, clip_w]);                         // lower jaw (yoke side)
      translate([0, jaw_t + panel_t, 0]) cube([upper_jaw_l, jaw_t, clip_w]); // upper jaw
    }
    // pan screw hole through lower jaw
    translate([pan_hole_x, jaw_t/2, clip_w/2]) cyl(d=m3_clear, h=jaw_t + 2*eps, orient=BACK);
    // grip screw insert through upper jaw (M3 x 4, press in from the outside face)
    translate([grip_hole_x, jaw_t*1.5 + panel_t, clip_w/2]) cyl(d=m3_insert_d, h=jaw_t + 2*eps, orient=BACK);
  }
}

if (part == "body") body();
else if (part == "cap") cap();
else if (part == "yoke") yoke();
else if (part == "clip") clip();

// ---- assembly preview (not for printing): clip on a panel, pod tilted ----
tilt = 25;
if (part == "assembly") {
  rotate([90,0,0]) clip();
  color("Gray", 0.3) translate([spine_t, -clip_w - 10, jaw_t]) cube([60, clip_w + 20, panel_t]);
  translate([pan_hole_x, -clip_w/2, 0]) {
    rotate([180,0,0]) yoke();
    translate([0, 0, -ear_piv_h]) rotate([tilt,0,0]) translate([0, 0, -piv_z]) {
      color("DimGray") body();
      color("SlateGray") translate([0, 0, z_top + cap_t]) rotate([180,0,0]) cap();
    }
  }
}

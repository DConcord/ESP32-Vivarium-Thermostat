// GY-906-DCI (MLX90614) sensor pod with tilt yoke and a wall bracket.
// GY-906 dimensions are measured (measurements sheet rows 1-5); bracket is a first pass.
// Parts: body (front-down), cap, yoke (base-down), bracket (on its side).
// Assembly: 2x M3 screws from OUTSIDE the PVC wall into inserts in the bracket
//   (no screw points inside the enclosure) -> M3 pan screw -> yoke -> 2x M3 tilt screws -> body.
// Kadrick M3 heat-set inserts (OD 4.5, tip 3.9): hole 4.0, depth = length + 1.5.
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "body";                  // "body" | "cap" | "yoke" | "bracket" | "assembly"
eps = 0.01;

// ---- parameters: GY-906-DCI (measured; PCB coords, origin = PCB centre, +Y = pin edge) ----
pcb = [11.41, 16.86, 1.57];     // X width, Y length, thickness
tube_d = 9.05;  tube_h = 20.43; // lens tube diameter, height above the board
tube_xy = [0, pcb.y/2 - 8.22];  // 8.22 from the pin edge, centred across the width
hole_d = 3.0;  hole_pitch = 6.35;  hole_from_end = 2.52;  // two holes at the far end
hole_xy = [for (s=[-1,1]) [s*hole_pitch/2, -pcb.y/2 + hole_from_end]];
back_parts_h = 1.17;            // tallest part on the back of the board

// ---- parameters: body ----
wall = 2;  clr = 0.3;
front_t = 2;  lip_w = 1;        // front plate; lip that stops the tube
sleeve_t = 1.2;                 // locating sleeve around the tube
ledge_w = 0.8;                  // PCB edges rest on this ledge
wire_h = 8;                     // wires soldered straight to the pads + 100 nF cap
post_d = 5;  m25_pilot_d = 2.1;  m25_pilot_depth = 6;  // M2.5 self-tapping screws hold the board
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

// ---- parameters: wall bracket (L profile, printed on its side) ----
br_w = 24;                      // bracket width (along the wall)
plate_t = 7;  plate_h = 34;     // wall plate thickness, height above the arm
arm_t = 5;  arm_reach = 28;     // arm thickness; wall face to pan screw
gusset = 14;                    // triangular brace between plate and arm
wall_screw_pitch = 12;  wall_screw_y = 26;  wall_insert_depth = 5.5;  // M3 x 4 inserts in the plate
pvc_t = 6;                      // PVC wall thickness (measurement sheet), preview only

// ---- derived ----
body_xy = [pcb.x + 2*(clr+wall), pcb.y + 2*(clr+wall)];
z_pcb = front_t + tube_h;               // PCB front face rests here
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
yoke_reach = max(ear_gap/2 + ear_t, swing_r);  // largest radius about the pan axis
arm_l = arm_reach + 8;

// ---- asserts ----
assert(wall >= 1.2);
assert(norm(tube_xy - hole_xy[1]) > tube_d/2 + hole_d/2, "PCB hole overlaps tube");
assert(abs(hole_xy[1].x) + post_d/2 <= under_xy.x/2 + wall, "PCB post outside body");
assert(back_parts_h + 4 < wire_h, "not enough room behind the board");
assert(piv_insert_depth < wall + piv_boss_l - 0.5, "pivot insert breaks into cavity");
assert(cap_tab.y - (cap_hole_y - body_xy.y/2) - 4.5/2 >= 1.2, "cap tab wall too thin");
assert(arm_reach > yoke_reach + 2, "pod swings into the wall below the arm");
assert(wall_insert_depth < plate_t - 1, "wall insert breaks through the plate");
assert(wall_screw_y - 4.5/2 > arm_t + gusset - 4, "wall screw hits the gusset");

// ---- body ----
module body() {
  difference() {
    union() {
      difference() {
        cuboid([body_xy.x, body_xy.y, z_top], rounding=corner_r, edges="Z", anchor=BOT);
        translate([0,0,front_t]) cuboid([under_xy.x, under_xy.y, z_pcb-front_t+eps], anchor=BOT);
        translate([0,0,z_pcb]) cuboid([pocket_xy.x, pocket_xy.y, z_top-z_pcb+eps], anchor=BOT);
      }
      // tube sleeve and two PCB screw posts
      translate([tube_xy.x, tube_xy.y, 0]) cyl(d=tube_d + 2*clr + 2*sleeve_t, h=z_pcb - 3, anchor=BOT);
      for (h = hole_xy) translate([h.x, h.y, 0]) cyl(d=post_d, h=z_pcb, anchor=BOT);
      // pivot bosses (inverted teardrop so the underside prints without support)
      for (s=[-1,1]) translate([s*(body_xy.x/2 + piv_boss_l/2 - eps), 0, piv_z])
        mirror([0,0,1]) teardrop(h=piv_boss_l + 2*eps, d=piv_boss_d, spin=90);
      // cap screw tabs, with a >45 deg wedge underneath so they print without support
      for (s=[-1,1]) translate([0, s*(body_xy.y/2 - eps), z_top - cap_tab_h]) hull() {
        translate([0, s*cap_tab.y/2, 0]) cuboid([cap_tab.x, cap_tab.y + eps, cap_tab_h], anchor=BOT);
        translate([0, s*eps/2, -cap_tab.y - 1]) cuboid([cap_tab.x, eps, eps], anchor=BOT);
      }
    }
    // tube bore and front aperture
    translate([tube_xy.x, tube_xy.y, front_t]) cyl(d=tube_d + 2*clr, h=z_pcb, anchor=BOT);
    translate([tube_xy.x, tube_xy.y, -eps]) cyl(d=tube_d + 2*clr - 2*lip_w, h=front_t + 2*eps, anchor=BOT);
    // M2.5 pilots in the posts
    for (h = hole_xy) translate([h.x, h.y, z_pcb - m25_pilot_depth]) cyl(d=m25_pilot_d, h=m25_pilot_depth+eps, anchor=BOT);
    // M3 inserts in pivot bosses and cap tabs
    for (s=[-1,1]) translate([s*(body_span_x/2 + eps), 0, piv_z])
      cyl(d=m3_insert_d, h=2*piv_insert_depth, orient=RIGHT);
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
    for (s=[-1,1]) translate([s*(ear_gap/2 + ear_t/2), 0, ear_piv_h]) cyl(d=m3_clear, h=ear_t + 2*eps, orient=RIGHT);
    // pan insert (M3 x 5, through; press in from the bracket side = print bed face)
    translate([0,0,-eps]) cyl(d=m3_insert_d, h=yoke_base_t + 2*eps, anchor=BOT);
  }
}

// ---- wall bracket: L profile in XY (X = out from the wall, Y = up), extruded along Z ----
module bracket() {
  difference() {
    linear_extrude(br_w) polygon([
      [0, 0], [arm_l, 0], [arm_l, arm_t], [plate_t + gusset, arm_t],
      [plate_t, arm_t + gusset], [plate_t, arm_t + plate_h], [0, arm_t + plate_h]]);
    // pan screw clearance hole through the arm (vertical in use)
    translate([arm_reach, arm_t/2, br_w/2]) cyl(d=m3_clear, h=arm_t + 2*eps, orient=BACK);
    // two M3 x 4 inserts in the wall face; screws come in from outside the enclosure
    for (s=[-1,1]) translate([-eps, wall_screw_y, br_w/2 + s*wall_screw_pitch/2])
      cyl(d=m3_insert_d, h=wall_insert_depth + eps, orient=RIGHT, anchor=BOT);
  }
}

if (part == "body") body();
else if (part == "cap") cap();
else if (part == "yoke") yoke();
else if (part == "bracket") bracket();

// ---- assembly preview (not for printing): bracket on the PVC wall, pod tilted ----
tilt = 25;
if (part == "assembly") {
  rotate([90,0,0]) bracket();                                  // wall face at x = 0, arm along +X
  color("Gray", 0.3) translate([-pvc_t, -br_w - 20, -30]) cube([pvc_t, br_w + 40, arm_t + plate_h + 40]);
  translate([arm_reach, -br_w/2, 0]) {
    rotate([180,0,0]) yoke();
    translate([0, 0, -ear_piv_h]) rotate([tilt,0,0]) translate([0, 0, -piv_z]) {
      color("DimGray") body();
      color("SlateGray") translate([0, 0, z_top + cap_t]) rotate([180,0,0]) cap();
    }
  }
}

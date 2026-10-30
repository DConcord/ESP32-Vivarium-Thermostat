// Main thermostat enclosure: base (mains bay + low-voltage bay) and lid.
// Dimensions from the measurements sheet (Google Sheets "Vivarium thermostat measurements").
// Frame: origin = outer back-left-bottom corner of the base, +Z up.
// -Y wall = BACK (inlet, outlet, cable grommets). +Y wall = FRONT (OLED window).
include <BOSL2/std.scad>
$fa = 1; $fs = 0.2;
part = "base";                  // "base" | "lid" (print); "assembly" | "mockup" | "mockup_open" | "empty" (preview)
eps = 0.01;

// ---- parameters ----
wall = 3;  floor_t = 3;
mains_w = 100;                  // mains bay interior width (X): SSR + cutoff relay
div_t = 2;                      // divider thickness
lv_w = 98;                      // low-voltage bay interior width (X): CircuitSetup board
in_y = 104;  in_h = 60;         // interior depth (Y) and height (Z): sized for the switched inlet
corner_r = 4;                   // outer vertical-edge rounding

boss_d = 9;                     // lid screw bosses in the 4 corners
// Fasteners: heat-set inserts only in the lid (opened often); everything else uses
// self-tapping screws for plastic into printed pilot holes.
m3_insert_d = 4.0;  m3_insert_depth = 7.5;     // lid screws: Kadrick M3 x 6 inserts
m3_pilot_d = 2.5;  m4_pilot_d = 3.4;          // self-tapping M3 (#4) and M4 (#6) pilots
m3_clear = 3.4;  m3_head_d = 6.2;  m3_head_depth = 1.5;

// Inkbird SSR-40DA (measured): 63.2 x 45 x 23, 4.4 mm holes 46.0 apart along the long axis
ssr_size = [63.2, 45];  ssr_hole_pitch = 46.0;
ssr_boss_d = 10;  ssr_boss_h = 8;  ssr_pilot_depth = 9.5;  // M4 self-tapping screws
ssr_cx = 37;  ssr_center_y = 76;  // front-left of the mains bay, clear of the corner boss
// Cutoff relay: Wemos D1 mini relay shield (SRD-05VDC-SL-C), no mounting holes.
// It drops onto 4 corner posts (L-shaped, open sides for wiring); header pins hang below.
// Screw terminals face the back (inlet/outlet), pin row with 5V/GND/D1 faces the divider.
relay_pcb = [26, 28.2, 1.6];    // X, Y, thickness (measured)
relay_lift = 14;                // PCB underside above the floor: room for header pins + dupont
relay_cy = 83;  relay_gap = 1.5;  // relay center Y; clearance from the divider
relay_clr = 0.25;  relay_post = 4;  relay_post_t = 1.6;  relay_ledge = 2.5;  relay_locate_h = 2;

// AC-14-F16A switched inlet (rocker switch + fuse + C14 in one), upright, ears left/right.
// Measured: body 27.48 x 47, flange 48.8 x 59, 3.5 mm ear holes 39.6 apart, 28 deep incl. tabs.
c14_cut = [28, 47.5];  c14_hole_pitch = 39.6;  c14_x = 31;
c14_flange = [48.8, 59];  c14_depth = 28;  c14_harness = 15;  // body depth incl. tabs; wire bend room
c14_pad_d = 9;  c14_pad_t = 6;  c14_pilot_depth = 7;   // inside pads; M3 self-tapping screws from outside
// NEMA 5-15R snap-in receptacle (measured): body 23.3 square; side clips grip walls up to 2.21
outlet_cut = [23.7, 23.7];  outlet_panel_t = 2.0;  outlet_x = 76;
outlet_pocket = [31, 31];       // inside thinning pocket around the cutout (covers the clips)

// Low-voltage bay
// Three rubber grommets (Vrupin kit) in the back wall, each with a slot up to the rim so
// pre-soldered cables drop in (slit the grommet); a lid tab with a concave bottom closes the
// slot so the grommet seats all the way round. Measured: 3/4 in = 24 flange, 20 groove bottom,
// 13 centre; 5/8 in = 19.7 flange, 15.5 groove bottom, 10.5 centre; grooves 1.8-2 wide.
//   [centre X offset from the LV bay's left wall, hole d, flange d, slot w, what passes]
grommets = [[16.5, 20.0, 24.0, 8, "Cat6 + 2 soil probes"],
            [45.5, 20.0, 24.0, 8, "2 DS18B20 + SHT30"],
            [72.5, 15.9, 19.7, 6, "USB (right-angle plug)"]];
grommet_panel_t = 1.8;          // grooves are 1.8-2 wide; wall thinned to this around each hole
grommet_z = 19;  grommet_pocket_extra = 3;  // pocket = flange + extra
lid_tab_clr = 0.3;
// CircuitSetup Project Box Breadboard (measured from photo via 2.54 mm hole pitch; verify)
pb_size = [95, 56];  pb_hole_pitch = [87.5, 48.5];  // measured: 3.1 mm holes, 2.2 mm edge to hole edge
pb_center_y = 55;  pb_edge_gap = 1.5;          // USB end of the board this far from the +X wall
// ESP32-DevKitC 38-pin on 8.5 mm female headers; micro-USB at the column-30 end, faces +X wall
esp_hdr_h = 7.4;  usb_in = 9.9;  usb_y_off = 0;   // measured: chip top 12.04 above the board (7.4 + 1.6 board + 3 can); port mouth 9.9 inside board edge
usb_h = 8;                      // measured: USB centre 8 above the board top (the ESP32 sits tilted, USB end lower)
standoff_d = 8;  standoff_h = 9;  pb_pilot_depth = 7;  // M3 self-tapping; 9 mm clears the 6 mm underside
div_notch = [10, 8];  div_notch_y = 42;  // wire pass-through at floor (Y width, Z height), center Y

// Lid
lid_t = 3;  lip_h = 3;  lip_t = 1.6;  lip_clr = 0.2;
// SH1106 1.3" OLED on the FRONT wall. The PCB drops into open-top grooves behind the
// window (glass against the wall), rests on a ledge, and the lid lip keeps it down.
oled_pcb = [35.4, 33.5, 1.6];   // width (X), height (Z), thickness (confirmed)
oled_glass_t = 1.2;             // measured: 2.8 total front of glass to back of board, minus 1.6 PCB
oled_win = [31, 19.5];  oled_view_top = 5;  // measured: lit area 19.5 tall, starting 5 below the pin edge (top)
oled_z0 = 14;                   // PCB bottom edge height: window roughly centred on the front wall
oled_clr = 0.3;  rail_t = 2;  rail_lip = 2;

// ---- derived ----
in_x = mains_w + div_t + lv_w;
outer = [in_x + 2*wall, in_y + 2*wall, in_h + floor_t];
div_x = wall + mains_w;                       // divider left face
lv_x0 = div_x + div_t;                        // LV bay interior start
lv_cx = lv_x0 + lv_w/2;
mains_cx = wall + mains_w/2;
relay_cx = div_x - relay_gap - relay_post_t - relay_clr - relay_pcb.x/2;
relay_in = [relay_pcb.x + 2*relay_clr, relay_pcb.y + 2*relay_clr];
pb_cx = outer.x - wall - pb_edge_gap - pb_size.x/2;
pb_top_z = floor_t + standoff_h + 1.6;
usb_z = pb_top_z + usb_h;
mid_z = floor_t + in_h/2;
boss_off = wall + boss_d/2 - 1;               // boss centers from outer edges
boss_pts = [for (x=[boss_off, outer.x-boss_off], y=[boss_off, outer.y-boss_off]) [x,y]];
oled_groove = oled_glass_t + oled_pcb.z + 2*oled_clr;   // depth behind the front wall
oled_w = oled_pcb.x + 2*oled_clr;
oled_y_in = outer.y - wall;                              // front wall inner face
oled_y_back = oled_y_in - oled_groove - rail_t;
oled_rail_top = oled_z0 + oled_pcb.y + 1;
oled_win_z = oled_z0 + oled_pcb.y - oled_view_top - oled_win.y/2;
g_x = [for (g = grommets) lv_x0 + g[0]];      // grommet centres (X)

// ---- asserts ----
assert(wall >= 2.0, "mains enclosure wall too thin");
assert(floor_t + ssr_boss_h - ssr_pilot_depth >= 1.2, "SSR pilot breaks through floor");
assert(c14_pilot_depth < wall + c14_pad_t - 1, "C14 pilot breaks through pad");
assert(standoff_d - m3_pilot_d >= 4, "standoff wall too thin around the pilot");
assert(standoff_h - pb_pilot_depth >= 0 && pb_pilot_depth <= standoff_h + floor_t - 1.2, "standoff pilot breaks through floor");
assert(c14_x - c14_hole_pitch/2 - 4 > wall, "C14 ears hit left wall");
assert(outlet_x + outlet_pocket.x/2 < div_x, "outlet pocket crosses divider");
assert(c14_x + c14_hole_pitch/2 + 4 < outlet_x - outlet_pocket.x/2, "C14 and outlet overlap");
assert(c14_x + c14_flange.x/2 < outlet_x - outlet_cut.x/2 - 1, "inlet flange overlaps outlet");
assert(mid_z + c14_cut.y/2 < outer.z - 3 && mid_z - c14_cut.y/2 > floor_t + 2, "inlet cutout does not fit the back wall");
assert(wall + c14_depth + c14_harness <= ssr_center_y - ssr_size.y/2, "no room for the inlet harness in front of the SSR");
assert(ssr_cx - ssr_size.x/2 > wall + 2, "SSR hits left wall");
assert(ssr_cx + ssr_size.x/2 + 3 < relay_cx - relay_in.x/2 - relay_post_t, "SSR hits relay posts");
assert(ssr_center_y + ssr_size.y/2 < outer.y - boss_off - boss_d/2, "SSR hits front-left boss");
assert(relay_cy - relay_in.y/2 - relay_post_t > div_notch_y + div_notch.x/2, "relay posts block divider notch");
assert(relay_cy + relay_in.y/2 + relay_post_t < outer.y - wall, "relay hits front wall");
assert(grommets[0][0] - (grommets[0][2] + grommet_pocket_extra)/2 > 0, "first grommet pocket hits the divider");
assert(lv_x0 + grommets[2][0] + (grommets[2][2] + grommet_pocket_extra)/2 < outer.x - boss_off - boss_d/2, "last grommet pocket hits the corner boss");
for (i = [0:len(grommets)-2]) assert(grommets[i+1][0] - grommets[i][0] > (grommets[i][2] + grommets[i+1][2])/2 + grommet_pocket_extra, "grommet pockets overlap");
assert(grommet_z - max([for (g = grommets) g[2]])/2 > floor_t, "grommet flange hits floor");
assert(oled_rail_top <= outer.z - lip_h - 0.3, "OLED rails hit lid lip");
assert(pb_center_y + pb_size.y/2 < oled_y_back - 1, "protoboard hits OLED rails");
assert(pb_cx - pb_size.x/2 > lv_x0 + 0.5, "protoboard does not fit the LV bay");
assert(pb_center_y + pb_size.y/2 < outer.y - boss_off - boss_d/2, "protoboard hits front bosses");

// axis-aligned box between two opposite corners (any order)
module box_between(p1, p2) {
  translate([min(p1.x,p2.x), min(p1.y,p2.y), min(p1.z,p2.z)])
    cube([abs(p2.x-p1.x), abs(p2.y-p1.y), abs(p2.z-p1.z)]);
}

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
      for (s=[-1,1]) translate([ssr_cx + s*ssr_hole_pitch/2, ssr_center_y, 0])
        cyl(d=ssr_boss_d, h=floor_t+ssr_boss_h, anchor=BOT);
      // protoboard standoffs
      for (sx=[-1,1], sy=[-1,1]) translate([pb_cx + sx*pb_hole_pitch.x/2, pb_center_y + sy*pb_hole_pitch.y/2, 0])
        cyl(d=standoff_d, h=floor_t+standoff_h, anchor=BOT);
      // relay shield corner posts: solid up to the ledge, L-walls above to locate the PCB
      post_h = floor_t + relay_lift + relay_pcb.z + relay_locate_h;
      for (sx=[-1,1], sy=[-1,1]) translate([relay_cx + sx*relay_in.x/2, relay_cy + sy*relay_in.y/2, 0]) {
        box_between([-sx*relay_ledge, -sy*relay_ledge, 0], [0, 0, floor_t + relay_lift]);           // ledge
        box_between([0, -sy*relay_post, 0], [sx*relay_post_t, sy*relay_post_t, post_h]);           // wall beyond X edge
        box_between([-sx*relay_post, 0, 0], [sx*relay_post_t, sy*relay_post_t, post_h]);           // wall beyond Y edge
      }
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
    // SSR pilots (M4 self-tapping)
    for (s=[-1,1]) translate([ssr_cx + s*ssr_hole_pitch/2, ssr_center_y, floor_t+ssr_boss_h-ssr_pilot_depth])
      cyl(d=m4_pilot_d, h=ssr_pilot_depth+eps, anchor=BOT);
    // protoboard pilots (M3 self-tapping)
    for (sx=[-1,1], sy=[-1,1]) translate([pb_cx + sx*pb_hole_pitch.x/2, pb_center_y + sy*pb_hole_pitch.y/2, floor_t+standoff_h-pb_pilot_depth])
      cyl(d=m3_pilot_d, h=pb_pilot_depth+eps, anchor=BOT);
    // divider wire notch
    translate([div_x-eps, div_notch_y - div_notch.x/2, floor_t-eps]) cube([div_t+2*eps, div_notch.x, div_notch.y]);
    // C14 inlet cutout + ear holes (-Y wall)
    translate([c14_x, wall/2, mid_z]) cube([c14_cut.x, wall+2*eps, c14_cut.y], center=true);
    for (s=[-1,1]) translate([c14_x + s*c14_hole_pitch/2, -eps, mid_z])
      cyl(d=m3_pilot_d, h=c14_pilot_depth+eps, orient=BACK, anchor=BOT);
    // outlet cutout + inside thinning pocket (-Y wall)
    translate([outlet_x, wall/2, mid_z]) cube([outlet_cut.x, wall+2*eps, outlet_cut.y], center=true);
    translate([outlet_x - outlet_pocket.x/2, outlet_panel_t, mid_z - outlet_pocket.y/2])
      cube([outlet_pocket.x, wall - outlet_panel_t + eps, outlet_pocket.y]);
    // grommet keyholes (back wall, LV bay): hole + slot to the rim + inside thinning pocket
    for (g = grommets) translate([lv_x0 + g[0], 0, 0]) {
      translate([0, -eps, grommet_z]) cyl(d=g[1], h=wall + 2*eps, orient=BACK, anchor=BOT);
      translate([-g[3]/2, -eps, grommet_z]) cube([g[3], wall + 2*eps, outer.z]);
      pocket_d = g[2] + grommet_pocket_extra;
      hull() for (z=[grommet_z, outer.z + pocket_d/2])
        translate([0, grommet_panel_t, z]) cyl(d=pocket_d, h=wall - grommet_panel_t + eps, orient=BACK, anchor=BOT);
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
      for (g = grommets) translate([lv_x0 + g[0], 0, 0]) difference() {
        translate([-g[3]/2 + lid_tab_clr, 0, grommet_z - outer.z])
          cube([g[3] - 2*lid_tab_clr, grommet_panel_t, outer.z - grommet_z + eps]);
        translate([0, -eps, grommet_z - outer.z]) cyl(d=g[1], h=grommet_panel_t + 2*eps, orient=BACK, anchor=BOT);
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
else if (part == "empty") { base(); color("SteelBlue", 0.25) translate([0, 0, outer.z]) lid_assembled(); }
else if (part == "assembly") {
  base();
  color("SteelBlue", 0.6) translate([0, 0, outer.z + 15]) lid_assembled();
}

// ---- placeholder components for visual mockups (approximate shapes, not for printing) ----
module components() {
  ssr_z = floor_t + ssr_boss_h;
  // SSR-40DA
  color("Gainsboro") translate([ssr_cx, ssr_center_y, ssr_z]) cuboid([ssr_size.x, ssr_size.y, 23], anchor=BOT);
  color("Silver") for (sx=[-1,1], sy=[-1,1]) translate([ssr_cx + sx*20, ssr_center_y + sy*11, ssr_z + 23]) cyl(d=7, h=2, anchor=BOT);
  // cutoff relay shield on its corner posts: relay toward the front, terminals toward the back
  rz = floor_t + relay_lift;
  translate([relay_cx, relay_cy, rz]) {
    color("#1e3a8a") cuboid([relay_pcb.x, relay_pcb.y, relay_pcb.z], anchor=BOT);
    color("#2563eb") translate([0, 4, relay_pcb.z]) cuboid([15.5, 19, 15.3], anchor=BOT);
    color("#3b82f6") translate([0, -relay_pcb.y/2 + 4.5, relay_pcb.z]) cuboid([16, 7.5, 9], anchor=BOT);
    color("#222") for (sx=[-1,1]) translate([sx*(relay_pcb.x/2 - 1.6), 0, 0]) cuboid([2.5, 20.3, 2.5], anchor=TOP);
    color("Silver") for (sx=[-1,1], k=[0:7]) translate([sx*(relay_pcb.x/2 - 1.6), -8.9 + k*2.54, 0]) cuboid([0.64, 0.64, 8.5], anchor=TOP);
  }
  // C14 inlet: flange outside, body inside
  color("#222") translate([c14_x, 0, mid_z]) {
    translate([0, -3, 0]) cuboid([c14_flange.x, 3, c14_flange.y], rounding=2, edges="Y", anchor=FRONT);
    cuboid([c14_cut.x - 0.5, c14_depth, c14_cut.y - 0.5], anchor=FRONT);
    color("#E53935") translate([0, -3, c14_cut.y/2 - 9]) cuboid([20, 4, 12], anchor=BACK);   // rocker switch
  }
  // power cord plug into the C14
  color("#333") translate([c14_x, -3, mid_z - c14_cut.y/2 + 12]) cuboid([24, 30, 20], rounding=3, anchor=BACK);
  // NEMA outlet: face flush outside, body inside
  color("#222") translate([outlet_x, 0, mid_z]) cuboid([outlet_cut.x - 0.5, 24, outlet_cut.y - 0.5], anchor=FRONT);
  color("#111") translate([outlet_x, -0.6, mid_z]) cuboid([outlet_cut.x + 2, 0.6, outlet_cut.y + 2], anchor=FRONT);
  // heat panel plug in the outlet
  color("#ddd") translate([outlet_x, -0.6, mid_z]) cuboid([22, 26, 24], rounding=3, anchor=BACK);
  // CircuitSetup board + ESP32-DevKitC on female headers (rows a and i, 0.9" apart), USB toward +X
  pb_z = floor_t + standoff_h;
  esp_x1 = pb_cx + pb_size.x/2 - usb_in;   // USB end of the ESP32 board
  esp_cx = esp_x1 - 55/2;
  color("#111") translate([pb_cx, pb_center_y, pb_z]) cuboid([pb_size.x, pb_size.y, 1.6], rounding=3, edges="Z", anchor=BOT);
  color("#333") for (sy=[-1,1]) translate([esp_cx + 2, pb_center_y + sy*22.86/2, pb_top_z]) cuboid([48.3, 2.5, esp_hdr_h], anchor=BOT);
  color("#1a1a1a") translate([esp_cx, pb_center_y, pb_top_z + esp_hdr_h]) cuboid([55, 28, 1.6], anchor=BOT);
  color("Silver") translate([esp_x1 - 55 + 9, pb_center_y, pb_top_z + esp_hdr_h + 1.6]) cuboid([18, 25.5, 3], anchor=BOT);
  color("Silver") translate([esp_x1, pb_center_y + usb_y_off, usb_z]) cuboid([5.5, 7.5, 3], anchor=RIGHT);
  // right-angle micro-USB plug turning toward the back, cable to the third grommet
  color("#222") translate([esp_x1, pb_center_y + usb_y_off, usb_z]) {
    cuboid([10, 12, 7], rounding=1.5, anchor=LEFT);
    translate([5, -6, 0]) cyl(d=3.5, h=pb_center_y - 6 - wall - 4, orient=FWD, anchor=BOT);
  }
  // OLED module in its grooves
  oy = oled_y_in - oled_glass_t - oled_clr;
  color("#1565c0") translate([lv_cx, oy, oled_z0]) cuboid([oled_pcb.x, oled_pcb.z, oled_pcb.y], anchor=BACK+BOT);
  color("#0b0b2a") translate([lv_cx, oy, oled_win_z]) cuboid([34.5, oled_glass_t, 23], anchor=FRONT);
  // grommets + cables
  for (g = grommets) translate([lv_x0 + g[0], 0, grommet_z]) {
    color("#151515") translate([0, grommet_panel_t/2, 0]) rotate([90,0,0]) difference() {
      union() {
        for (z=[-1,1]) translate([0,0,z*(grommet_panel_t/2 + 0.75)]) cyl(d=g[2], h=1.5);
        cyl(d=g[1], h=grommet_panel_t + eps);
      }
      cyl(d=g[1] - 7, h=10);
    }
  }
  cab = [[0, [[-2.6, 1.5, 6.0, "#3a7bd5"], [2.8, 1.5, 4.5, "#5a3d1e"], [0.1, -3.2, 4.5, "#5a3d1e"]]],  // Cat6 + 2 soil
         [1, [[-2.6, -1.5, 4.0, "#111"], [2.6, -1.5, 4.0, "#111"], [0, 2.6, 4.5, "#111"]]],          // DS18B20 x2 + SHT30
         [2, [[0, 0, 3.5, "#222"]]]];                                                               // USB
  for (g = cab) for (c = g[1]) color(c[3])
    translate([g_x[g[0]] + c[0], -40, grommet_z + c[1]]) cyl(d=c[2], h=40 + 20, orient=BACK, anchor=BOT);
}

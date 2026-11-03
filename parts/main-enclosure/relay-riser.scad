// Relay-shield riser: drop-in insert for the base's four relay corner posts, so the shield
// can be used with its header pins soldered and Dupont jumpers on 5V/GND/D1.
// The board is located by its header strips (two rails with a slot for the pins), not by its
// outline, and gaps under 5V, GND and D1 let the Dupont housings hang through.
// Orientation in the box: Dupont gaps on the divider side, toward the back (screw terminals
// face the back wall, as in the base). Print frame-down.
include <main-enclosure.scad>
part = "riser";                 // "riser" (print) | "riser_check" (in the base, with a mock shield)

// ---- parameters ----
pin_pitch = 2.54;  pins_n = 8;  row_gap = 22.86;   // Wemos D1 mini shield header geometry
strip_w = 2.5;  strip_h = 2.5;  pin_below = 6;     // header plastic strip; pin length below it
pin_slot_w = 1.0;               // prints a little narrower: pins should be snug
rail_w = 4;  rail_h = 16;       // rails carry the header strips; tall so the Dupont wires can bend underneath
dupont_w = 3.0;  dupont_pins = [1, 2, 6];          // 5V, GND, D1 counted from the terminal end
first_pin = 9.15;               // terminal-end board edge to pin 1 centre (28.2 - 1.27 - 7*2.54)
frame_clr = 0.25;  frame_rim = 3;

// ---- derived (riser frame: origin at the post pocket centre, Z = 0 on the corner ledges) ----
frame = [relay_in.x - 2*frame_clr, relay_in.y - 2*frame_clr];
frame_h = relay_pcb.z + relay_locate_h;        // ledge top up to the post tops
rail_top = frame_h + rail_h;                   // header strips rest here
row_y0 = -relay_pcb.y/2 + first_pin;           // pin 1 (terminal end = -Y = back)
pin_y = [for (i = [1:pins_n]) row_y0 + (i-1)*pin_pitch];
riser_z = floor_t + relay_lift;                // ledge top in the base frame
pcb_z = riser_z + rail_top + strip_h;          // shield PCB underside in the base frame

// ---- asserts ----
assert(rail_top + riser_z - dupont_w > floor_t, "riser below the floor");
assert(riser_z + rail_top - floor_t >= 14 + 8, "no room under the rails for Dupont housings + wire bend");
assert(rail_top - pin_below - 0.5 >= 1.5, "too little floor under the pin slots");
assert(pcb_z + relay_pcb.z + 15.3 < outer.z - lip_h - 1, "relay hits the lid lip");
assert(row_gap/2 + rail_w/2 <= frame.x/2 + 0.5, "rails overhang the frame too far");
assert(pin_y[pins_n-1] + pin_pitch/2 <= frame.y/2 + 0.5, "pin rows run off the frame");

module riser() {
  difference() {
    union() {
      // rim frame that drops between the post walls and sits on the corner ledges
      difference() {
        cuboid([frame.x, frame.y, frame_h], anchor=BOT);
        cuboid([frame.x - 2*frame_rim, frame.y - 2*frame_rim, 3*frame_h], anchor=CENTER);
      }
      // rails under the two header rows
      // (trimmed to the frame below the post tops, where the post walls are)
      for (s=[-1,1]) translate([s*row_gap/2, 0, 0]) intersection() {
        cuboid([rail_w, frame.y, rail_top], anchor=BOT);
        union() {
          translate([-s*row_gap/2, 0, 0]) cuboid([frame.x, frame.y, frame_h + eps], anchor=BOT);
          translate([0, 0, frame_h]) cuboid([2*rail_w, frame.y, rail_top], anchor=BOT);
        }
      }
    }
    // pin slots, from the rail top down past the pin tips (the floor under them ties the rail together)
    for (s=[-1,1]) translate([s*row_gap/2, (pin_y[0] + pin_y[pins_n-1])/2, rail_top - pin_below - 0.5])
      cuboid([pin_slot_w, pin_y[pins_n-1] - pin_y[0] + pin_pitch, rail_h + frame_h], anchor=BOT);
    // Dupont gaps on the divider (+X) row, through everything and out past the frame edge
    for (p = dupont_pins) translate([row_gap/2 - dupont_w/2, pin_y[p-1] - (pin_pitch + 0.5)/2, -eps])
      cube([frame.x/2 - row_gap/2 + dupont_w/2 + 1, pin_pitch + 0.5, rail_top + 2*eps]);
  }
}

if (part == "riser") riser();
else if (part == "riser_check") {
  base();
  translate([relay_cx, relay_cy, riser_z]) color("Orange") riser();
  // mock shield: PCB, header strips + pins, relay, Dupont housings
  translate([relay_cx, relay_cy, 0]) {
    color("#1e3a8a") translate([0, 0, pcb_z]) cuboid([relay_pcb.x, relay_pcb.y, relay_pcb.z], anchor=BOT);
    color("#2563eb") translate([2, 4, pcb_z + relay_pcb.z]) cuboid([15.5, 19, 15.3], anchor=BOT);
    for (s=[-1,1]) translate([s*row_gap/2, 0, 0]) {
      color("#222") translate([0, (pin_y[0] + pin_y[pins_n-1])/2, pcb_z]) cuboid([strip_w, pins_n*pin_pitch, strip_h], anchor=TOP);
      color("Silver") for (y = pin_y) translate([0, y, pcb_z - strip_h]) cuboid([0.64, 0.64, pin_below], anchor=TOP);
    }
    color("#111") for (p = dupont_pins) translate([row_gap/2, pin_y[p-1], pcb_z - strip_h]) cuboid([2.5, 2.5, 14], anchor=TOP);
  }
}

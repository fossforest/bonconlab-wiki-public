// =====================================================================
//  CT clamp box for a 10 AWG x 4C cord  —  companion to wago_junction_box
//
//  The cord passes straight through, unbroken.  Inside the box the outer
//  jacket is stripped and the two hot conductors each run through their
//  own Zemismart SDM02T-TZ split-core CT.  The CTs lie on their sides,
//  side by side across Y, lead faces against the back and front walls,
//  jaws facing the centre lane (hinge up).  Neutral + ground run down the
//  lane between the CTs.  CT leads exit through U-slots in the outer walls.
//
//  Units: mm.  Print base + lid.  PETG or ASA/ABS — NOT PLA.
//  Snap-fit lid (press the barbs in from outside to release).
//  Set  part = "base" / "lid" / "both"  then F6 + export STL.
// =====================================================================

/* [Cord] */
cord_od     = 18.0;   // measured with calipers (10/4 STW, 5 mm conductors)
cord_clear  = 0.6;    // extra on slot width

/* [CT clamps — Zemismart SDM02T-TZ 120 A split-core (drawing: 35.5 W x 45.6 H x 30.8 D, window D16)] */
ct_w       = 35.5;  // body width  -> box HEIGHT when lying on its side
ct_h       = 45.6;  // body height (lead face to jaw) -> along Y
ct_d       = 30.8;  // body depth (window axis) -> along X, conductor runs through
ct_fit     = 0.5;   // per-side pocket clearance
ct_lead_d  = 4.5;   // twin-lead OD (measured ~4 mm)
ct_lead_z  = ct_w/2;// lead exits the centre of the lead face
ct_win_y   = 12;    // window centre from the jaw end (from the drawing)
ct_lane    = 12;    // lane between the two CTs for neutral + ground
ct_top_clr = 2.5;   // headroom above the CT under the lid
fence_h    = 4.0;
fence_t    = 1.2;

/* [Box] */
wall      = 2.4;
floor_t   = 2.0;
lid_t     = 2.5;
lip_t     = 1.6;
lip_h     = 2.0;
lip_clear = 0.3;
fan_out   = 28;    // saddle -> CT: room for the hots to jog into their windows

/* [Strain relief — zip-tie saddle] */
saddle_h = 7;      // must clear tie_z + tie_h + tie_w/2 (peaked roof) by >= 1.2
saddle_x = 10;
tie_w    = 5.5;    // zip-tie tunnel width (fits a 4.8 mm tie)
tie_h    = 2.0;    // tunnel height at the straight walls; a 45 deg peak sits on top (no bridge)
tie_z    = 0.8;    // tunnel floor above saddle base

/* [Snap-fit (PETG-sized)] */
snap_n    = 2;     // hooks per long (X) side
snap_w    = 8;     // hook width (X)
snap_edge = 14;    // hook centre distance from each end wall
arm_len   = 12;    // arm length below lid underside (longer = softer snap)
barb_d    = 1.0;   // barb protrusion into the wall window
barb_h    = 2.4;   // barb height (45 deg chamfers top and bottom for printing)
win_clear = 0.3;   // window clearance around the barb, per side

/* [Output] */
part = "both"; // ["base","lid","both"]

// ---------------- derived ----------------
ct_px   = ct_d + 2*ct_fit;                 // pocket size along X
ct_py   = ct_h + 2*ct_fit;                 // pocket size along Y
inner_x = 2*(3 + saddle_x + fan_out) + ct_px;
inner_y = 2*ct_py + ct_lane;
inner_h = ct_w + 2*ct_fit + ct_top_clr;
outer_x = inner_x + 2*wall;
outer_y = inner_y + 2*wall;
rim_z   = floor_t + inner_h;
slot_w  = cord_od + cord_clear;
cord_y  = wall + inner_y/2;
cord_zb = floor_t + saddle_h;              // cord bottom
cord_zc = cord_zb + cord_od/2;             // cord centre
cord_zt = cord_zb + cord_od;               // cord top
tab_w   = slot_w - 0.4;
tab_h   = rim_z - (cord_zt + 0.4);
ct_x0   = wall + 3 + saddle_x + fan_out;   // pocket X start (fence inside face)
ct_xc   = ct_x0 + ct_px/2;                 // CT / lead-slot X centre
ct_lead_zb = floor_t + ct_fit + ct_lead_z - ct_lead_d/2;   // lead slot bottom
lead_tab_w = ct_lead_d - 0.4;
lead_tab_h = rim_z - (ct_lead_zb + ct_lead_d + 0.4);
snap_xs = [for (i=[0:snap_n-1]) wall + snap_edge + i*(outer_x - 2*(wall+snap_edge))/max(snap_n-1,1)];
$fn = 64;

module cord_slot() {                    // U-slot in the x=0 end wall, open to the top
    translate([-1, cord_y, cord_zc]) rotate([0,90,0]) cylinder(d=slot_w, h=wall+2);
    translate([-1, cord_y-slot_w/2, cord_zc]) cube([wall+2, slot_w, rim_z]);
}

module lead_slot() {                    // U-slot in the y=0 wall, centred on x=0, open to the top
    translate([0, -1, ct_lead_zb + ct_lead_d/2]) rotate([-90,0,0]) cylinder(d=ct_lead_d, h=wall+2);
    translate([-ct_lead_d/2, -1, ct_lead_zb + ct_lead_d/2]) cube([ct_lead_d, wall+2, rim_z]);
}

module saddle(x0) {
    // block with a Y-axis tunnel under the deck for a zip tie;
    // tunnel has a 45 deg peaked roof so it prints with no bridge
    sw = cord_od + 4;
    tx = (saddle_x - tie_w)/2;
    translate([x0, cord_y - sw/2, floor_t]) difference() {
        cube([saddle_x, sw, saddle_h]);
        translate([0, sw+1, 0]) rotate([90,0,0]) linear_extrude(sw+2)
            polygon([[tx, tie_z], [tx+tie_w, tie_z], [tx+tie_w, tie_z+tie_h],
                     [tx+tie_w/2, tie_z+tie_h+tie_w/2], [tx, tie_z+tie_h]]);
    }
}

// CT pocket against the y=0 wall: two side fences + a front fence (wall closes the back)
module ct_pocket() {
    translate([ct_x0-fence_t, wall, floor_t])        cube([fence_t, ct_py+fence_t, fence_h]);
    translate([ct_x0+ct_px,   wall, floor_t])        cube([fence_t, ct_py+fence_t, fence_h]);
    translate([ct_x0-fence_t, wall+ct_py, floor_t])  cube([ct_px+2*fence_t, fence_t, fence_h]);
}

module snap_windows() {
    ww = snap_w + 2*win_clear;
    wh = barb_h + 2*win_clear;
    z0 = rim_z - arm_len - win_clear;       // barb occupies the bottom barb_h of the arm
    for (x=snap_xs, y=[-1, outer_y - wall - 1])
        translate([x - ww/2, y, z0]) cube([ww, wall+2, wh]);
}

// One hook, lid print orientation, on the y=0 side; barb points toward -Y (into the wall).
module snap_hook() {
    li = wall + lip_clear;
    zt = lid_t + arm_len;
    translate([-snap_w/2, 0, 0]) {
        translate([0, li, lid_t]) cube([snap_w, lip_t, arm_len]);
        rotate([90,0,90]) linear_extrude(snap_w)
            polygon([[li, zt - barb_h], [li - barb_d, zt - barb_h + barb_d],
                     [li - barb_d, zt - barb_d], [li, zt], [li + 0.01, zt], [li + 0.01, zt - barb_h]]);
    }
}

module base() {
    difference() {
        union() {
            // shell
            difference() {
                cube([outer_x, outer_y, rim_z]);
                translate([wall, wall, floor_t]) cube([inner_x, inner_y, inner_h+1]);
            }
            // zip-tie saddles
            saddle(wall + 3);
            saddle(outer_x - wall - 3 - saddle_x);
            // CT pockets, mirrored about the box centreline
            ct_pocket();
            translate([0, outer_y, 0]) mirror([0,1,0]) ct_pocket();
        }
        // cord entries
        cord_slot();
        translate([outer_x - wall, 0, 0]) cord_slot();
        // CT lead slots through the back and front walls
        translate([ct_xc, 0, 0]) lead_slot();
        translate([ct_xc, outer_y, 0]) mirror([0,1,0]) lead_slot();
        // snap windows through both long walls
        snap_windows();
    }
}

module lid() {   // modelled in PRINT orientation: plate on bed, lip/tabs/hooks up
    li = wall + lip_clear;
    union() {
        cube([outer_x, outer_y, lid_t]);
        // continuous alignment lip
        translate([li, li, lid_t])                     cube([outer_x-2*li, lip_t, lip_h]);
        translate([li, outer_y-li-lip_t, lid_t])       cube([outer_x-2*li, lip_t, lip_h]);
        translate([li, li, lid_t])                     cube([lip_t, outer_y-2*li, lip_h]);
        translate([outer_x-li-lip_t, li, lid_t])       cube([lip_t, outer_y-2*li, lip_h]);
        // tabs that drop into the cord slots and sit just above the cord
        translate([0,            cord_y-tab_w/2, lid_t]) cube([wall, tab_w, tab_h]);
        translate([outer_x-wall, cord_y-tab_w/2, lid_t]) cube([wall, tab_w, tab_h]);
        // tabs that close the CT lead slots above the lead
        translate([ct_xc-lead_tab_w/2, 0,            lid_t]) cube([lead_tab_w, wall, lead_tab_h]);
        translate([ct_xc-lead_tab_w/2, outer_y-wall, lid_t]) cube([lead_tab_w, wall, lead_tab_h]);
        // snap hooks on both long sides
        for (x=snap_xs) {
            translate([x, 0, 0]) snap_hook();
            translate([x, outer_y, 0]) mirror([0,1,0]) snap_hook();
        }
    }
}

if (part == "base" || part == "both") base();
if (part == "lid"  || part == "both") translate([0, outer_y + 10, 0]) lid();

echo(str("CT box: ", outer_x, " x ", outer_y, " mm; base height ", rim_z, " mm; lid ", lid_t + max(lip_h, tab_h, arm_len, lead_tab_h),
         " mm; inner ", inner_x, " x ", inner_y, " x ", inner_h,
         "; CT windows at y=", wall + ct_fit + ct_h - ct_win_y, " and ", outer_y - (wall + ct_fit + ct_h - ct_win_y),
         ", z=", floor_t + ct_fit + ct_w/2, "; cord centre y=", cord_y, " z=", cord_zc));

// =====================================================================
//  Inline junction box for rejoining a cut 10 AWG x 4C cord
//  with 4x WAGO 221-612 lever nuts  —  FIRST DRAFT (WAGOs only)
//
//  Units: mm.  Print base + lid.  PETG or ASA/ABS — NOT PLA.
//  Lid fastening: fastening = "snap" (cantilever hooks into wall windows,
//  press the barbs in from outside to release) or "screws" (4x M3 bosses).
//  Set  part = "base" / "lid" / "both"  then F6 + export STL.
//
//  BEFORE PRINTING: measure your cord OD with calipers and set cord_od.
//  10/4 STW is usually 14.5–18 mm; this file is set to 18.0 (measured).
// =====================================================================

/* [Cord] */
cord_od     = 18.0;   // measured with calipers (10/4 STW, 5 mm conductors)
cord_clear  = 0.6;    // extra on slot width

/* [WAGO 221-612 (datasheet: 16 W x 21.1 D x 10.1 H)] */
wago_w   = 16.0;   // across the two ports (X)
wago_d   = 21.1;   // along wire axis (Y)
wago_h   = 10.1;
wago_n   = 4;
wago_gap = 2.0;
wago_fit = 0.3;    // per-side pocket clearance
fence_h  = 4.0;
fence_t  = 1.2;

/* [Box] */
wall      = 2.4;
floor_t   = 2.0;
inner_h   = 30;    // interior height (>= cord_od + saddle_h + ~5 so the lid tab stays > 2 mm)
lid_t     = 2.5;
lip_t     = 1.6;
lip_h     = 2.0;
lip_clear = 0.3;
end_zone  = 28;    // room at each end for saddle + wire fan-out
front_ch  = 16;    // wire channel in front of WAGO entry faces
back_gap  = 3;

/* [Strain relief — zip-tie saddle] */
saddle_h = 7;      // must clear tie_z + tie_h + tie_w/2 (peaked roof) by >= 1.2
saddle_x = 10;
tie_w    = 5.5;    // zip-tie tunnel width (fits a 4.8 mm tie)
tie_h    = 2.0;    // tunnel height at the straight walls; a 45 deg peak sits on top (no bridge)
tie_z    = 0.8;    // tunnel floor above saddle base

/* [Fastening] */
fastening = "snap"; // ["snap","screws"]

/* [Snap-fit (PETG-sized)] */
snap_n    = 2;     // hooks per long side
snap_w    = 8;     // hook width (X)
snap_edge = 14;    // hook centre distance from each end wall
arm_len   = 12;    // arm length below lid underside (longer = softer snap)
barb_d    = 1.0;   // barb protrusion into the wall window
barb_h    = 2.4;   // barb height (45 deg chamfers top and bottom for printing)
win_clear = 0.3;   // window clearance around the barb, per side

/* [Screws] */
boss_d    = 7;
boss_hole = 2.6;   // 2.6 = M3 self-tap in PETG ; 4.0 = M3 heat-set insert
lid_hole  = 3.4;
boss_inset = 0.5;  // boss overlaps into the wall (avoids a tangent, non-manifold edge)

/* [Output] */
part = "both"; // ["base","lid","both"]

// ---------------- derived ----------------
row_len = wago_n*wago_w + (wago_n-1)*wago_gap;
inner_x = 2*end_zone + row_len;
inner_y = back_gap + wago_d + front_ch;
outer_x = inner_x + 2*wall;
outer_y = inner_y + 2*wall;
rim_z   = floor_t + inner_h;
slot_w  = cord_od + cord_clear;
cord_y  = wall + inner_y/2;
cord_zb = floor_t + saddle_h;          // cord bottom
cord_zc = cord_zb + cord_od/2;         // cord centre
cord_zt = cord_zb + cord_od;           // cord top
tab_w   = slot_w - 0.4;
tab_h   = rim_z - (cord_zt + 0.4);
boss_c  = wall + boss_d/2 - boss_inset;
snap    = (fastening == "snap");
lip_bo  = snap ? 0 : boss_d + lip_clear;   // lip notch clear of bosses (none when snapping)
snap_xs = [for (i=[0:snap_n-1]) wall + snap_edge + i*(outer_x - 2*(wall+snap_edge))/max(snap_n-1,1)];
$fn = 64;

module boss_positions() {
    for (x=[boss_c, outer_x-boss_c], y=[boss_c, outer_y-boss_c])
        translate([x,y,0]) children();
}

module cord_slot() {                    // U-slot, open to the top
    translate([-1, cord_y, cord_zc]) rotate([0,90,0]) cylinder(d=slot_w, h=wall+2);
    translate([-1, cord_y-slot_w/2, cord_zc]) cube([wall+2, slot_w, rim_z]);
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

module base() {
    difference() {
        union() {
            // shell
            difference() {
                cube([outer_x, outer_y, rim_z]);
                translate([wall, wall, floor_t]) cube([inner_x, inner_y, inner_h+1]);
            }
            // corner bosses (screw variant only)
            if (!snap) boss_positions() cylinder(d=boss_d, h=rim_z);
            // WAGO fences (open toward +Y front channel)
            for (i=[0:wago_n-1]) {
                x0 = wall + end_zone + i*(wago_w+wago_gap) - wago_fit;
                y0 = wall + back_gap - wago_fit;
                pw = wago_w + 2*wago_fit;
                pd = wago_d + 2*wago_fit;
                translate([x0-fence_t, y0-fence_t, floor_t]) cube([pw+2*fence_t, fence_t, fence_h]);
                translate([x0-fence_t, y0-fence_t, floor_t]) cube([fence_t, pd+fence_t, fence_h]);
                translate([x0+pw,      y0-fence_t, floor_t]) cube([fence_t, pd+fence_t, fence_h]);
            }
            // zip-tie saddles
            saddle(wall + 3);
            saddle(outer_x - wall - 3 - saddle_x);
        }
        // cord entries
        cord_slot();
        translate([outer_x - wall, 0, 0]) cord_slot();
        // screw holes
        if (!snap) boss_positions() translate([0,0,rim_z-14]) cylinder(d=boss_hole, h=20);
        // snap windows through both long walls
        if (snap) snap_windows();
    }
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
        // barb: 45 deg catch face underneath (printable), 45 deg lead-in on top
        translate([0, 0, 0]) rotate([90,0,90]) linear_extrude(snap_w)
            polygon([[li, zt - barb_h], [li - barb_d, zt - barb_h + barb_d],
                     [li - barb_d, zt - barb_d], [li, zt], [li + 0.01, zt], [li + 0.01, zt - barb_h]]);
    }
}

module lid() {   // modelled in PRINT orientation: plate on bed, lip/tabs up
    difference() {
        union() {
            cube([outer_x, outer_y, lid_t]);
            // alignment lip (4 bars, notched clear of the bosses)
            li = wall + lip_clear;  bo = lip_bo;
            translate([li+bo, li, lid_t])                       cube([outer_x-2*(li+bo), lip_t, lip_h]);
            translate([li+bo, outer_y-li-lip_t, lid_t])         cube([outer_x-2*(li+bo), lip_t, lip_h]);
            translate([li, li+bo, lid_t])                       cube([lip_t, outer_y-2*(li+bo), lip_h]);
            translate([outer_x-li-lip_t, li+bo, lid_t])         cube([lip_t, outer_y-2*(li+bo), lip_h]);
            // tabs that drop into the cord slots and sit just above the cord
            translate([0,          cord_y-tab_w/2, lid_t]) cube([wall, tab_w, tab_h]);
            translate([outer_x-wall, cord_y-tab_w/2, lid_t]) cube([wall, tab_w, tab_h]);
            // snap hooks on both long sides
            if (snap) for (x=snap_xs) {
                translate([x, 0, 0]) snap_hook();
                translate([x, outer_y, 0]) mirror([0,1,0]) snap_hook();
            }
        }
        if (!snap) boss_positions() translate([0,0,-1]) cylinder(d=lid_hole, h=lid_t+2);
    }
}

if (part == "base" || part == "both") base();
if (part == "lid"  || part == "both") translate([0, outer_y + 10, 0]) lid();

echo(str("Outer footprint: ", outer_x, " x ", outer_y, " mm; base height ", rim_z, " mm; lid ", lid_t + max(lip_h, tab_h, snap ? arm_len : 0), " mm; fastening ", fastening));

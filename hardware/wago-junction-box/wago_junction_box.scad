// =====================================================================
//  Inline junction box for rejoining a cut 10 AWG x 4C cord
//  with 4x WAGO 221-612 lever nuts  —  FIRST DRAFT (WAGOs only)
//
//  Units: mm.  Print base + lid.  PETG or ASA/ABS — NOT PLA.
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
inner_h   = 28;    // interior height (>= cord_od + saddle_h + ~5 so the lid tab stays > 2 mm)
lid_t     = 2.5;
lip_t     = 1.6;
lip_h     = 2.0;
lip_clear = 0.3;
end_zone  = 28;    // room at each end for saddle + wire fan-out
front_ch  = 16;    // wire channel in front of WAGO entry faces
back_gap  = 3;

/* [Strain relief — zip-tie saddle] */
saddle_h = 5;
saddle_x = 10;
tie_w    = 6;      // zip-tie tunnel width
tie_h    = 2.2;    // zip-tie tunnel height
tie_z    = 1.0;    // tunnel floor above saddle base

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
    // block with a Y-axis tunnel under the deck for a zip tie
    sw = cord_od + 4;
    translate([x0, cord_y - sw/2, floor_t]) difference() {
        cube([saddle_x, sw, saddle_h]);
        translate([(saddle_x-tie_w)/2, -1, tie_z]) cube([tie_w, sw+2, tie_h]);
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
            // corner bosses
            boss_positions() cylinder(d=boss_d, h=rim_z);
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
        boss_positions() translate([0,0,rim_z-14]) cylinder(d=boss_hole, h=20);
    }
}

module lid() {   // modelled in PRINT orientation: plate on bed, lip/tabs up
    difference() {
        union() {
            cube([outer_x, outer_y, lid_t]);
            // alignment lip (4 bars, notched clear of the bosses)
            li = wall + lip_clear;  bo = boss_d + lip_clear;
            translate([li+bo, li, lid_t])                       cube([outer_x-2*(li+bo), lip_t, lip_h]);
            translate([li+bo, outer_y-li-lip_t, lid_t])         cube([outer_x-2*(li+bo), lip_t, lip_h]);
            translate([li, li+bo, lid_t])                       cube([lip_t, outer_y-2*(li+bo), lip_h]);
            translate([outer_x-li-lip_t, li+bo, lid_t])         cube([lip_t, outer_y-2*(li+bo), lip_h]);
            // tabs that drop into the cord slots and sit just above the cord
            translate([0,          cord_y-tab_w/2, lid_t]) cube([wall, tab_w, tab_h]);
            translate([outer_x-wall, cord_y-tab_w/2, lid_t]) cube([wall, tab_w, tab_h]);
        }
        boss_positions() translate([0,0,-1]) cylinder(d=lid_hole, h=lid_t+2);
    }
}

if (part == "base" || part == "both") base();
if (part == "lid"  || part == "both") translate([0, outer_y + 10, 0]) lid();

echo(str("Outer footprint: ", outer_x, " x ", outer_y, " mm; base height ", rim_z, " mm; lid ", lid_t + max(lip_h, tab_h), " mm"));

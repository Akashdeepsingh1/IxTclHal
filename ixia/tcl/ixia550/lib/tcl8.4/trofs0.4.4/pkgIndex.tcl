if {[package vsatisfies 8.4 8.5]} {
if {![package vsatisfies [package provide Tcl]     8.4]} {return}
} elseif {[package vcompare [package provide Tcl]     8.4]} {return}
package ifneeded trofs 0.4.4     [list load [file join $dir trofs044.dll]]

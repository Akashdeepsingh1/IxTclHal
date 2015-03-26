#############################################################################################
#
# pkgIndex.tcl  
#
# Copyright © 1997-2006 by IXIA.
# All Rights Reserved.
#
#
#############################################################################################

set currDir [file dirname [info script]]

if {$::tcl_platform(platform) != "unix"} {
    # if this package is already loaded, then don't load it again
    if {[lsearch [package names] IxTclNetwork] != -1} {
        return
    }
} else {
    lappend ::auto_path $currDir
  
}

package ifneeded IxTclNetwork 5.30 [list source [file join $currDir IxTclNetwork.tcl]]

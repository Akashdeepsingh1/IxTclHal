#############################################################################################
#
# pkgIndex.tcl  
#
# Copyright © 1997-2006 by IXIA.
# All Rights Reserved.
#
#
#############################################################################################

if {$::tcl_platform(platform) != "unix"} {
    # if this package is already loaded, then don't load it again
    if {[lsearch [package names] IxTclNetwork] != -1} {
        return
    }
} else {
    lappend ::auto_path [file dirname [info script]]
}

package ifneeded IxTclNetwork 5.50.121.48 [list source [file join [file dirname [info script]] IxTclNetwork.tcl]]


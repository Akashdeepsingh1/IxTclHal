#############################################################################################
#
# IxTclNetwork.tcl  - required file for package require IxTclNetwork
#
# Copyright © 1997-2006 by IXIA.
# All Rights Reserved.
#
#
#############################################################################################

namespace eval ::ixTclNet {}
namespace eval ::ixTclPrivate {}  ;#Use this namespace for procs that we don't want to expose to user.

foreach fileItem1 [glob -nocomplain [file dirname [info script]]/*] {
    # We only are concerned with directories
    if {[file isdirectory $fileItem1]} {
        foreach fileItem2 [glob -nocomplain $fileItem1/*] {
            if {![file isdirectory $fileItem2]} {
                source  $fileItem2
            } 
        }
    } 
}

source [file join [file dirname [info script]] ixTclNetworkSetup.tcl]

package provide IxTclNetwork 5.50.121.48


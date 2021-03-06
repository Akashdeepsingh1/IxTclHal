#
# iwidgets.tcl
# ----------------------------------------------------------------------
# Invoked automatically by [incr Tk] upon startup to initialize
# the [incr Widgets] package.
# ----------------------------------------------------------------------
#  AUTHOR: Mark L. Ulferts               EMAIL: mulferts@spd.dsccc.com
#
#  @(#) $Id: iwidgets.tcl.in,v 1.5 2007/06/10 19:28:16 hobbs Exp $
# ----------------------------------------------------------------------
#                Copyright (c) 1995  Mark L. Ulferts
# ======================================================================
# See the file "license.terms" for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package require Tcl 8.0
package require Tk 8.0
package require Itcl 3.2
package require Itk 3.2

namespace eval ::iwidgets {
    namespace export *

    variable library [file dirname [info script]]
    variable version 4.0.2

    lappend auto_path $iwidgets::library
    variable subdir
    foreach subdir {generic scripts} {
	if {[file isdirectory [file join $iwidgets::library $subdir]]} {
	    lappend auto_path [file join $iwidgets::library $subdir]
	}
    }
    unset subdir
}

package provide Iwidgets $iwidgets::version

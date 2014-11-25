# pkgIndex.tcl --
#
#       Handcrafted for TclXSLT.
#
# Copyright (c) 2001-2003 Zveno Pty Ltd
# http://ww.zveno.com/
#
# $Id: pkgIndex.tcl.in,v 1.7 2003/03/09 11:30:42 balls Exp $

package ifneeded xslt 2.6 "
    load [file join [list $dir] Tclxslt26.dll] Xslt
    source [file join $dir tclxslt.tcl]
"

package ifneeded xslt::cache 2.6 [list source [file join $dir xsltcache.tcl]]


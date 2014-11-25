# changelog.tcl --
#
#	Handling of ChangeLog's.
#
# Copyright (c) 2003 Andreas Kupries <andreas_kupries@sourceforge.net>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: changelog.tcl,v 1.1 2003/03/29 00:18:58 andreas_kupries Exp $


# FUTURE -- Expand pre-parsed log (nested lists) into flat structures
# FUTURE --  => date/author/file/cref + cref/text
# FUTURE -- I.e. relational/tabular structure, useable in table displays,
# FUTURE -- sort by date, author, file to see aggregated changes
# FUTURE --  => Connectivity to 'struct::matrix', Reports!


package require Tcl 8.2
package require textutil

namespace eval ::doctools {}
namespace eval ::doctools::changelog {
    namespace export scan toDoctools
}

# ::doctools::changelog::scan --
#
#	Scan a ChangeLog generated by 'emacs' and extract the relevant information.
#
# Result
#	List of entries. Each entry is a list of three elements. These
#	are date, author, and commentary. The commentary is a list of
#	sections. Each section is a list of two elements, a list of
#	files, and the associated text.


proc ::doctools::changelog::scan {text} {
    set text [split $text \n]
    set n    [llength $text]

    set entries [list]
    set clist [list]
    set files [list]
    set comment ""
    set first 1

    for {set i 0} {$i < $n} {incr i} {
	set line [lindex $text $i]

	if {[regexp "^\[^ \t\]" $line]} {
	    # No whitespace at the front, start a new entry

	    closeEntry

	    # For the upcoming entry. Quick extraction first, string
	    # based in case of failure.

	    if {[catch {
		set date    [string trim [lindex $line 0]]
		set author  [string trim [lrange $line 1 end]]
	    }]} {
		set pos    [string first " " $line]
		set date   [string trim [string range $line 0   $pos]]
		set author [string trim [string range $line $pos end]]
	    }
	    continue
	}

	# Inside of an entry.

	set line [string trim $line]

	if {[string length $line] == 0} {
	    # Next comment section
	    closeSection
	    continue
	}

	# Line is not empty. Split into file and comment parts,
	# remember the data.

	if {[string first "* " $line] == 0} {
	    if {[regexp {^\* (.*):[ 	]} $line full fname]} {
		set line [string range $line [string length $full] end]
	    } elseif {[regexp {^\* (.*):$} $line full fname]} {
		set line ""
	    } else {
		# There is no filename
		set fname ""
		set line [string range $line 2 end] ; # Get rid of "* ".
	    }

	    set detail ""
	    while {[string first "(" $fname] >= 0} {
		if {[regexp {\([^)]*\)} $fname detailx]} {
		    regsub {\([^)]*\)} $fname {} fnameNew
		} elseif {[regexp {\([^)]*} $fname detailx]} {
		    regsub {\([^)]*} $fname {} fnameNew
		} else {
		    break
		}
		append detail " " $detailx
		set fname [string trim $fnameNew]
	    }
	    if {$detail != {}} {set line "$detail $line"}
	    if {$fname  != {}} {lappend files $fname}
	}

	append comment $line\n
    }

    closeEntry
    return $entries
}


proc ::doctools::changelog::closeSection {} {
    upvar clist clist comment comment files files

    if {
	([string length $comment] > 0) ||
	([llength $files] > 0)
    } {
	lappend clist   [list $files [string trim $comment]]
	set     files   [list]
	set     comment ""	
    }
    return
}

proc ::doctools::changelog::closeEntry {} {
    upvar clist clist comment comment files files first first
    upvar date date author author entries entries

    if {!$first} {
	closeSection
	lappend entries [list $date $author $clist]
    }
    set first 0
    set clist [list]
    set files [list]
    set comment ""
    return
}

# ::doctools::changelog::merge --
#
#	Merge several preprocessed changelogs (see scan) into one structure.


proc ::doctools::changelog::merge {args} {

    if {[llength $args] == 0} {return {}}
    if {[llength $args] == 1} {return [lindex $args 0]}

    set res [list]
    array set tmp {}

    # Merge up ...

    foreach entries $args {
	foreach e $entries {
	    foreach {date author comments} $e break
	    if {![info exists tmp($date,$author)]} {
		lappend res [list $date $author]
		set tmp($date,$author) $comments
	    } else {
		foreach section $comments {
		    lappend tmp($date,$author) $section
		}
	    }
	}
    }

    # ... And construct the final result

    set args $res
    set res [list]
    foreach key [lsort -decreasing $args] {
	foreach {date author} $key break
	lappend res [list $date $author $tmp($date,$author)]
    }
    return $res
}


# ::doctools::changelog::toDoctools --
#
#	Convert a preprocessed changelog log (see scan) into a doctools page.
#
# Arguments:
#	evar, cvar, fvar: Name of the variables containing the preprocessed log.
#
# Results:
#	A string containing a properly formatted ChangeLog.
#

proc ::doctools::changelog::q {text} {return "\[$text\]"}

proc ::doctools::changelog::toDoctools {title module version entries} {

    set     linebuffer [list]
    lappend linebuffer [q "manpage_begin [list ${title}-changelog n $version]"]
    lappend linebuffer [q "titledesc [list "$title ChangeLog"]"]
    lappend linebuffer [q "moddesc [list $module]"]
    lappend linebuffer [q description]
    lappend linebuffer [q "list_begin definitions compact"]

    foreach entry $entries {
	foreach {date author commentary} $entry break

	lappend linebuffer [q "lst_item \"[q "emph [list $date]"] -- [string map {{"} {\"} {\"} {\\\"}} $author]\""]

	if {[llength $commentary] > 0} {
	    lappend linebuffer [q nl]
	}

	foreach section $commentary {
	    foreach {files text} $section break
	    if {$text != {}} {
		set text [string map {[ [lb] ] [rb]} [textutil::adjust $text]]
	    }

	    if {[llength $files] > 0} {
		lappend linebuffer [q "list_begin definitions"]

		foreach f $files {
		    lappend linebuffer [q "lst_item [q "file [list $f]"]"]
		}
		if {$text != {}} {
		    lappend linebuffer ""
		    lappend linebuffer $text
		    lappend linebuffer ""
		}

		lappend linebuffer [q list_end]
	    } elseif {$text != {}} {
		# No files
		lappend linebuffer [q "list_begin bullet"]
		lappend linebuffer [q bullet]
		lappend linebuffer ""
		lappend linebuffer $text
		lappend linebuffer ""
		lappend linebuffer [q list_end]
	    }
	}
	lappend linebuffer [q nl]
    }

    lappend linebuffer [q list_end]
    lappend linebuffer [q manpage_end]
    return [join $linebuffer \n]
}

#------------------------------------
# Module initialization

package provide doctools::changelog 0.1

#############################################################################################
#   Version 5.50
#   
#   File: pkgIndex.tcl
#
#   Copyright ©  IXIA
#   All Rights Reserved.
#
#   This command is called inside the IxExplorer TclDlg.cpp and TclLibrary.cpp
#   files to overload the some commands that cause problems when called
#   inside the IxExplorer Tcl console
#
#############################################################################################

package ifneeded IxTclExplorer 1.00 {

	if { [catch {package req IxTclHal} result ] } {
		puts "Failed to load the IxTclExplorer package - $result"
		return -code error 
	} else {
		set env(IXIA_TCLEXPLORER_LIBRARY) $env(IXTCLHAL_LIBRARY)/../IxTclExplorer

		# We need to source the utils.tcl file, so that it doesn't get sourced later
		# when some other proc that lives in the same file is called and caused the utils.tcl 
		# be sourced, which will override the below redefined cleanUp
		source [file join $env(IXTCLHAL_LIBRARY)/Generic utils.tcl]	
		source [file join $env(IXIA_TCLEXPLORER_LIBRARY) explorerMacroUtils.tcl]	
		
		# exit gets called when cleanUp is called.
		proc ::cleanUp {{exitStat 0}} \
		{
			ixExplorerMacro::cleanUp
		}

		package provide IxTclExplorer 1.0
	}	
}





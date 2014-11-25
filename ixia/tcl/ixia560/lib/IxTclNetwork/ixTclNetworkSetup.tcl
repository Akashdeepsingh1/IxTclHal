##################################################################################
#   
#   File: ixTclNetworkSetup.tcl
#
#   Copyright ©  IXIA
#   All Rights Reserved.
#
# Description: Package initialization file.
#              This file is executed when you use "package require IxTclNetwork" to
#              load the IxTclNetwork library package. 
#
#
#############################################################################################

set env(IXTCLNETWORK_LIBRARY) [file dirname [info script]]

switch $tcl_platform(platform) {
   windows {
      set pathToScript [file dirname [info script]]
      set installDir [file normalize [file join $pathToScript .. .. ..]]
      set localDll [file join $installDir tcl8.4 bin IxTclNetwork_vc8.dll]
      if { [file exists $localDll] } {
	      #puts "loading $localDll"
	      load $localDll IxTclNetwork
      } else {
          #expected case is the first one.  this script is in installDir/TclScripts/Lib/IxTclNetwork, and should load installDir/IxTclNetwork.dll
	      set tclBinDir [file normalize [file join  $env(IXTCLNETWORK_LIBRARY) .. .. ..]]
	      set libDll [file join $tclBinDir IxTclNetwork.dll]
	      lappend triedPaths $tclBinDir

          #in older builds, we sometimes had the dll in installDir/TclScripts/bin or installDir/tcl8.4/bin.  I guess those cases should go away?
	      if {![file exists $tclBinDir] || ![file isdirectory $tclBinDir] || ![file exists $libDll]} {
              # intermission code so it works with current installer, shouldn't be needed once 404313 is resolved
		      set tclBinDir [file normalize [file join  $env(IXTCLNETWORK_LIBRARY) .. .. .. tcl8.4 bin]]
		      lappend triedPaths $tclBinDir
		      set libDll [file join $tclBinDir IxTclNetwork.dll]
		      if {![file exists $tclBinDir] || ![file isdirectory $tclBinDir] || ![file exists $libDll]} {
                  # intermission code so it works with current installer, shouldn't be needed once 404313 is resolved
	    	      set tclBinDir [file normalize [file join  $env(IXTCLNETWORK_LIBRARY) .. .. bin]]
		          lappend triedPaths $tclBinDir
		          set libDll [file join $tclBinDir IxTclNetwork.dll]
		      }
		      #lappend auto_path [file join $::_IXIA_INSTALL_ROOT]
	      }
	      set libDll [file join [pwd] IxTclNetwork_vc8.dll]
	      load $libDll IxTclNetwork
	      #lappend auto_path [file join $::_IXIA_INSTALL_ROOT]
      }
   }
   unix {
      set loadFile [file join [file dirname [info script]] libIxTclNetwork[info sharedlibextension]]
      load $loadFile IxTclNetwork
      ixNet setSessionParameter logFile [pwd]/ixNetTclEventLog.txt
   }
}




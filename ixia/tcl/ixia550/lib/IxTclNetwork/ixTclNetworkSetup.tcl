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

set genPath [file join $env(IXTCLNETWORK_LIBRARY) Generic]

lappend auto_path $env(IXTCLNETWORK_LIBRARY)

switch $tcl_platform(platform) {
   windows {
      set orgDirPath [pwd]
      set localDll [file join $orgDirPath IxTclNetwork_vc8.dll]
      if { [file exists $localDll] } {
	      load $localDll IxTclNetwork
      } else {
	      set tclBinDir [file join  $env(IXTCLNETWORK_LIBRARY) .. .. bin]
	      if {[catch {cd $tclBinDir} cdResult]} {
		      set tclBinDir [registry get {HKEY_LOCAL_MACHINE\Software\Ixia Communications\IxNetwork\InstallInfo} HOMEDIR]
		      cd [file join  $tclBinDir]
		      #lappend auto_path [file join $::_IXIA_INSTALL_ROOT]
	      }
	      set libDll [file join [pwd] IxTclNetwork_vc8.dll]
	      load $libDll IxTclNetwork
	      #lappend auto_path [file join $::_IXIA_INSTALL_ROOT]
	      cd [file join $orgDirPath]
      }
   }
   unix {
      set loadFile [file join $currDir libIxTclNetwork[info sharedlibextension]]
      load $loadFile IxTclNetwork
   }
}

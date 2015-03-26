# IxiaWish.tcl sets up the Tcl environment to use the correct multiversion-compatible 
# applications, as specified by Application Selector.

# Note: this file must remain compatible with tcl 8.3, because it will be sourced by scriptgen
namespace eval ::ixiaInstall:: {
    # For debugging, you can point this to an alternate location.  It should
    # point to a directory that contains the "TclScripts" subdirectory.
    set tclDir		"C:/Program Files/Ixia/IxOS/5.50-EA-SP1/"

    # For debugging, you can point this to an alternate location.  It should
    # point to a directory that contains the IxTclHal.dll
	set ixosTclDir	"C:/Program Files/Ixia/IxOS/5.50-EA-SP1/"

    set tclLegacyDir [file join $tclDir "../.."]

    # Calls appinfo to add paths to IxOS dependencies (such as IxLoad or IxNetwork).
    proc ixAddPathsFromAppinfo {installdir} {
        package require registry
        
        set installInfoFound false
        foreach {reg_path} [list "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\AppInfo\\InstallInfo" "HKEY_CURRENT_USER\\SOFTWARE\\Ixia Communications\\AppInfo\\InstallInfo"] {
            if { [ catch {registry get $reg_path "HOMEDIR"} r] == 0 } {
                set appinfo_path $r
                set installInfoFound true
                break
            }
        }
        # If the registy information was not found in either place, warn the user
        if { [string equal $installInfoFound "false"] } {        
            return -code error "Could not find AppInfo registry entry"
        }   
         
        # Call appinfo to get the list of all dependencies:
        regsub -all "\\\\" $appinfo_path "/" appinfo_path      
        set appinfo_executable [file attributes "$appinfo_path/Appinfo.exe" -shortname]
        set appinfo_command "|$appinfo_executable --app-path \"$installdir\" --get-dependencies"
        set appinfo_handle [open $appinfo_command r+ ]
        set appinfo_session {}

        while { [gets $appinfo_handle line] >= 0 } {
            # Keep track of the output to report in the error message below
            set appinfo_session "$appinfo_session $line\n"
            
            regsub -all "\\\\" $line "/" line
            regexp "^(.+):\ (.*)$" $line all app_name app_path
            # If there is a dependency listed, add the path.
            if {![string equal $app_path ""] } {
                # Only add it if it's not already present:
                if { -1 == [lsearch -exact $::auto_path $app_path ] } {
                    lappend ::auto_path $app_path
                    lappend ::auto_path [file join $app_path "TclScripts/lib"]
                    append ::env(PATH) [format ";%s" $app_path]                    
                }
            }
        }
        
        # If appinfo returned a non-zero result, this catch block will trigger.
        # In that case, show what we tried to do, and the resulting response.
        if { [catch {close $appinfo_handle} r] != 0} {
            return -code error "Appinfo error, \"$appinfo_command\" returned: $appinfo_session"
        }        
    }

    # Adds all needed Ixia paths
    proc ixAddPaths {installdir} {
        set ::env(IXTCLHAL_LIBRARY) [file join $installdir "TclScripts/lib/IxTcl1.0"]
        
        lappend ::auto_path $installdir
        lappend ::auto_path [file join $installdir "TclScripts/lib"]
        lappend ::auto_path [file join $installdir "TclScripts/lib/IxTcl1.0"]
        if { [catch {::ixiaInstall::ixAddPathsFromAppinfo $installdir} result] } {
            # Not necessarily fatal
            puts [format "WARNING!!! Unable to add paths from Appinfo: %s" $result]
        }
        append ::env(PATH) ";${installdir}"
        
        # Fall back to the old locations, in case a non-multiversion-aware 
        # IxLoad or IxNetwork is installed.
        lappend ::auto_path [file join $installdir "../../TclScripts/lib"]
        append ::env(PATH) [format ";%s" [file join $installdir "../.."]]

		if {![string equal $::ixiaInstall::tclDir $::ixiaInstall::ixosTclDir]} {
			append ::env(PATH) [format ";%s" $::ixiaInstall::ixosTclDir]
		}			
    }
}
::ixiaInstall::ixAddPaths $::ixiaInstall::tclDir

catch {
    # Try to set things up for Wish.  
    # This section will not run in IxExplorer or IxTclInterpreter, hence the catch block.
    if {[lsearch [package names] "Tk"] >= 0} {
        console show
        wm iconbitmap . [file join $::ixiaInstall::tclDir "ixos.ico"]
        
        # It is not easy to tell ActiveState wish from the Ixia-compiled wish.
        # The tcl_platform variable shows one difference: ActiveState implements threading
        if {![info exists ::tcl_platform(threaded)]} {           
            # Activestate prints this on its own, otherwise, we add it here:
            puts -nonewline "(TclScripts) 1 % "
        }        
    }
}

#############################################################################################
#   Version 5.50
#   
#   File: ixTclServicesSetup.tcl
#
#   Copyright ©  IXIA
#   All Rights Reserved.
#
#############################################################################################
package req IxTclHal
package provide IxTclServices 5.50

lappend auto_path [file dirname [info script]]

set ixServicesCmds { serviceManager dispatchService captureService genericService }

# NOTE: Need to redefine cleanUp here for IxTclServices,
# so that it can do package forget IxTclServices
if {[info proc cleanUp] != ""} {
    if {[info proc cleanUpOld] == ""} {
        rename cleanUp cleanUpOld
    }
} else {
    catch {source [file join $::env(IXTCLHAL_LIBRARY) Generic utils.tcl]}
    if {[info proc cleanUpOld] == ""} {
        rename cleanUp cleanUpOld
    }
}

	

proc cleanUp {} \
{
	cleanUpOld
	package forget IxTclServices
	return
}


if [isWindows] {
    catch {
        set serviceManagerPtr [TCLServiceManager serviceManager]
        if {$serviceManagerPtr == ""} {
	        puts "Error instantiating TCLServiceManager object!"
	        return 1
        }

        if {[TCLDispatchService dispatchService $serviceManagerPtr] == ""} {
	        puts "Error instantiating TCLDispatchService object!"
	        return 1
        }

        if {[TCLCaptureService captureService $serviceManagerPtr] == ""} {
	        puts "Error instantiating TCLCaptureService object!"
	        return 1
        }

        if {[TCLGenericService genericService $serviceManagerPtr] == ""} {
	        puts "Error instantiating TCLGenericService object!"
	        return 1
        }
    }
} else {
    if {[tclServer::isTclServerConnected]} {
        remoteDefine $ixServicesCmds
    }
}

eval lappend ::halCommands $ixServicesCmds







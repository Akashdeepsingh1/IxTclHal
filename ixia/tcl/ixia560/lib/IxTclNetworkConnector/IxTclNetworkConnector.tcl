#
#
#
if {[catch { package require IxTclNetwork } err]} {
    set pat {/*/Ixia/IxNetwork/5.*/TclScripts/lib/IxTclNetwork/IxTclNetwork.tcl}
    set fname [glob $pat]
    if {[llength $fname] == 0} {
        puts stderr "cannot find file in glob '$pat'"
    } else {
        set fname [lindex $fname end]
        source $fname
    }
}
package require IxTclNetwork
package require comm
package require snit
namespace eval ::IxTclNetworkConnector {}

if {[llength [info commands ::IxTclNetworkConnector::client]] == 0} {
#------------------------------------------------------------------------------
rename ::ixNet ::_connector_ixNet 
proc ::ixNet {args} {
    set subcmd [lindex $args 0]
    if {[string equal $subcmd "-async"]} {
        set subcmd [lindex $args 1]
    }
    if {[string equal $subcmd "connect"]} {
        return [eval [linsert $args 0 ::_default_ixn_connector $subcmd]]
    } elseif {[string equal [lindex $args 0] "disconnect"]} {
        return [eval [linsert $args 0 ::_default_ixn_connector $subcmd]]
    } elseif {[string equal $subcmd "connectiontoken"]} {
        return [eval [linsert $args 0 ::_default_ixn_connector $subcmd]]
    } elseif {[string equal $subcmd "rendezvous"]} {
        return [eval [linsert $args 0 ::_default_ixn_connector $subcmd]]
    }
    set cmd [linsert $args 0 ::_connector_ixNet]
    eval $cmd
}
#------------------------------------------------------------------------------
::snit::type ::IxTclNetworkConnector::client {
    variable BackendToken ""
    variable ConnectorServerPort 8009
    variable ConnectorServerHost "localhost"
    variable State "disconnected"
    variable JoinVersion 1.0
    variable ClientApp "IxNetwork"
    variable ClientVersion ""
    variable Trace 0
    constructor {args} {
        #$self configurelist $args
        if {[info exists ::env(IxTclNetworkConnector_DEBUG)]} {
            set Trace 1
        }
    }
    destructor {
    }

    method trace {s} {
        if {$Trace} { puts stderr "*** $self: $s" }
    }
    method commid {} {
        if {$State == "connected"} {
            return [list $ConnectorServerPort $ConnectorServerHost]
        }
        return {}
    }
    method send {args} {
        set cmd [linsert $args 0 ::comm::comm send [$self commid]]
        $self trace "$cmd"
        eval $cmd
    }

    typemethod getopt {arg_list start_index opt default_value} {
        set max [llength $arg_list]
        for {set x $start_index} {$x < $max} {incr x} {
            set item [lindex $arg_list $x] 
            if {[string equal $item $opt]} {
                if {$max>$x+1} {
                    return [lindex $arg_list [incr x]]
                }
            }
        }
        return $default_value
    }

    method connect {args} {
        $self trace "connect call: $args"
        set ax 0; set async 0 
        if {[lindex $args 0] == "-async"} {
            set async 1; incr ax
        }
        set ahost [lindex $args [incr ax]]
        set ConnectorServerHost $ahost

        if {[lindex $args [incr ax]] == "-port"} {
            set aport [lindex $args [incr ax]]
            set ConnectorServerPort $aport
        } else {
            set ConnectorServerPort 8009
        }
        set ClientVersion [$type getopt $args 0 -version ""] 

        if {$State != "disconnected"} {
            $self trace "not disconnected, call underlying and return"
            return [eval [linsert $args 0 ::_connector_ixNet]]]
        }

        # call the connection service to get the host/port
        set failed [catch {
            set tmp_commid [list $ConnectorServerPort $ConnectorServerHost]
            $self trace "using connection server '$tmp_commid'"
            set BackendToken [::comm::comm send $tmp_commid join \
                -clientusername [$self clientusername] \
                -joinversion $JoinVersion \
                -clientapp $ClientApp \
                -clientversion $ClientVersion \
            ]
            array set joinbag $BackendToken
            if {![info exists joinbag(-port)]} {
                error "missing port element in returned connection token"
            }
            if {![info exists joinbag(-host)]} {
                error "missing host element in returned connection token"
            }
            set backend_port $joinbag(-port)
            set backend_host $joinbag(-host)
        } err]
        if {$failed} {
            catch { ::comm::comm shutdown $tmp_commid } shutdownerr
            set BackendToken ""; set backend_port ""; set backend_host ""
            return -code error $err
        }
        set failed [catch {
            set xargs {}
            if {$async} {
                lappend xargs -async
            }
            lappend xargs connect $backend_host -port $backend_port
            if {[string length $ClientVersion]} {
                lappend xargs -version $ClientVersion
            }
            set xcmd [linsert $xargs 0 ::_connector_ixNet]
            $self trace "Underlying connect: $xcmd"
            set rval [eval $xcmd]
        } err]
        if {$failed} {
            $self trace "clean up failure to join the connection server"
            catch { ::comm::comm send $tmp_commid leave $BackendToken } leaveerr
            set BackendToken ""
            catch { ::comm::comm shutdown $tmp_commid } shutdownerr
            set State "disconnected"
            return -code error $err
        } else {
            set State "connected"
        }
        return $rval
    }
    method disconnect {args} {
        set ax 0; set async 0 
        if {[lindex $args 0] == "-async"} {
            set async 1; incr ax
        }
        if {$State != "connected"} {
            return [eval [linsert $args 0 ::_connector_ixNet]]]
        }


        set underlying_failed [catch {
            array set joinbag $BackendToken
            set backend_port $joinbag(-port)
            set backend_host $joinbag(-host)

            if {$async} {
                set underlying_rval [::_connector_ixNet \
                    -async disconnect $backend_host -port $backend_port]
            } else {
                set underlying_rval [::_connector_ixNet \
                    disconnect $backend_host -port $backend_port]
            }
        } underlying_err]

        set leave_failed [catch { 
            ::comm::comm send [$self commid] leave -token $BackendToken 
        } leave_err]
        if {$leave_failed} {
            catch {puts stderr "disconnect: leave: $leave_error"}
        }

        set backend_port ""; set backend_host ""
        catch { ::comm::comm shutdown [$self commid] } shutdownerr
        set State "disconnected"

        if {$underlying_failed} {
            return -code error $underlying_err
        } else {
            return $underlying_rval
        }

        return [eval [linsert $args 0 ::_connector_ixNet]]]
    }
    method connectiontoken {args} {
        return $BackendToken
    }
    method clientusername {} {
        if {[info exists ::tcl_platform(user)]} {
            return $::tcl_platform(user)
        }
        return "(unknown)"
    }
    method rendezvous {subcmd args} {
        if {[llength $args] == 1} {set args [lindex $args 0]}
        array set o [list -connectiontoken [$self connectiontoken]]
        array set o $args
        if {$State == "connected"} {
            return -code error "Client is already connected"
        } elseif {$State == "disconnected"} {
            if {[string length [$self connectiontoken]] == 0} {
                return -code error \
                "Client does not have a rendezvous connection token. It has probably never connected during it's current session."
            }
            $self trace "connectiontoken is [$self connectiontoken]"

            set tmp_commid [list $ConnectorServerPort $ConnectorServerHost]
            set failed [catch {
                set BackendToken [::comm::comm send $tmp_commid rendezvous \
                    -clientusername [$self clientusername] \
                    -connectiontoken $BackendToken \
                    -clientapp $ClientApp \
                    -clientversion $ClientVersion \
                ]
                array set joinbag $BackendToken
            } err]

            if {$failed} {
                set backend_port ""; set backend_host ""
                catch { ::comm::comm shutdown $tmp_commid } shutdownerr
                return -code error "$err"
            } else {
                if {![info exists joinbag(-port)]} {
                    error "missing port element in returned connection token"
                }
                if {![info exists joinbag(-host)]} {
                    error "missing host element in returned connection token"
                }
                set backend_port $joinbag(-port)
                set backend_host $joinbag(-host)
            }

            set failed [catch {
                set xargs {}
                lappend xargs connect $backend_host -port $backend_port
                if {[string length $ClientVersion]} {
                    lappend xargs -version $ClientVersion
                }
                set xcmd [linsert $xargs 0 ::_connector_ixNet]
                $self trace "Underlying connect: $xcmd"
                set rval [eval $xcmd]
            } err]
            if {$failed} {
                set backend_port ""; set backend_host ""
                set State "disconnected"
                return -code error $err
            } else {
                set State "connected"
                return $rval
            }

        } else {
            return -code error "Client is in unknown state '$State'"
        }
    }
    method state {} {
        return $State
    }
}
::IxTclNetworkConnector::client ::_default_ixn_connector

#------------------------------------------------------------------------------
}

package provide IxTclNetworkConnector 5.40

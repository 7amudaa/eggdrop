########################################################
# Set flag required for checking the status of a port. #
########################################################

set portcheck_setting(flag) "-|-"

set portcheck_setting(cmd_pub) "!port"

set portcheck_setting(cmd_dcc) "portchk"

set portcheck_setting(read) 1

set portcheck_setting(onjoin) 0

set portcheck_setting(ports) "1080 21 23 4000 10000 1 1304 139 22 443"

set portcheck_setting(exemptflag) "+E"

set portcheck_setting(autoban_svr) 0

set portcheck_setting(autoban_list) 0

set portcheck_setting(global) 0

set portcheck_setting(bantime) 5

set portcheck_setting(onotice) 1

set portcheck_setting(bold) 1

set portcheck_setting(PORTCHECK:) 1

####################
# Code begins here #
####################

if {![string match 1.6.* $version]} {
	putlog "\002PORTCHECK:\002 \002CRITICAL ERROR\002 PortCheck.tcl requires eggdrop 1.6.x to run."
	die "\002PORTCHECK:\002 \002CRITICAL ERROR\002 PortCheck.tcl requires eggdrop 1.6.x to run."
}
bind pub $portcheck_setting(flag) $portcheck_setting(cmd_pub) portcheck_scan_pub
bind dcc $portcheck_setting(flag) $portcheck_setting(cmd_dcc) portcheck_scan_dcc
bind join - * portcheck_onjoin_scan
setudef flag portcheck

proc portcheck_dopre {} {
	global portcheck_setting
	if {!$portcheck_setting(PORTCHECK:)} {
		return ""
	} elseif {!$portcheck_setting(bold)} {
		return "PORTCHECK: "
	} else {
		return "\002PORTCHECK:\002 "
	}
}
proc portcheck_onjoin_scan {nick uhost hand chan} {
	global portcheck_setting portcheck_chans
	if {($portcheck_setting(onjoin)) && ($portcheck_setting(ports) != "") && (![matchattr $hand $portcheck_setting(exemptflag)])} {
		foreach i [channel info $chan] {
			if {([string match "+portcheck" $i]) && ([botisop $chan])} {
				set host [lindex [split $uhost @] 1]
				foreach p $portcheck_setting(ports) {
					if {![catch {set sock [socket -async $host $p]} error]} {
						set timerid [utimer 15 [list portcheck_timeout_join $sock]]
						fileevent $sock writable [list portcheck_connected_join $nick $chan $sock $host $p $timerid]
					}
				}
				break
			}
		}
	}
}
proc portcheck_scan_pub {nick uhost hand chan text} {
	global portcheck_setting
	set host [lindex $text 0]
	set port [lindex $text 1]
	if {$port == ""} {
		putquick "NOTICE $nick :Usage: $portcheck_setting(cmd_pub) <host> <port>"
	} else {
		if {[catch {set sock [socket -async $host $port]} error]} {
			putquick "PRIVMSG $chan :Connection to $host \($port\) was refused."
		} else {
			set timerid [utimer 15 [list portcheck_timeout_pub $chan $sock $host $port]]
			fileevent $sock writable [list portcheck_connected_pub $chan $sock $host $port $timerid]
		}
	}
}
proc portcheck_scan_dcc {hand idx text} {
	global portcheck_setting
	set host [lindex $text 0]
	set port [lindex $text 1]
	if {$port == ""} {
		putdcc $idx "[portcheck_dopre]Usage: .$portcheck_setting(cmd_dcc) <host> <port>"
	} else {
		if {[catch {set sock [socket -async $host $port]} error]} {
			putdcc $idx "[portcheck_dopre]Connection to $host \($port\) was refused."
		} else {
			set timerid [utimer 15 [list portcheck_timeout $idx $sock $host $port]]
			fileevent $sock writable [list portcheck_connected $idx $sock $host $port $timerid]
		}
	}
}
proc portcheck_connected {idx sock host port timerid} {
	killutimer $timerid
	if {[set error [fconfigure $sock -error]] != ""} {
		close $sock
		putdcc $idx "[portcheck_dopre]Connection to $host \($port\) failed. \([string totitle $error]\)"
	} else {
		fileevent $sock writable {}
		fileevent $sock readable [list portcheck_read $idx $sock $host $port]
		putdcc $idx "[portcheck_dopre]Connection to $host \($port\) accepted."
	}
}
proc portcheck_timeout {idx sock host port} {
	close $sock
	putdcc $idx "[portcheck_dopre]Connection to $host \($port\) timed out."
}
proc portcheck_read {idx sock host port} {
	global portcheck_setting
	if {$portcheck_setting(read)} {
		if {[gets $sock read] == -1} {
			putdcc $idx "[portcheck_dopre]EOF On Connection To $host \($port\). Socket Closed."
			close $sock
		} else {
			putdcc $idx "[portcheck_dopre]$host \($port\) > $read"
		}
	} else {
		close $sock
	}
}
proc portcheck_connected_pub {chan sock host port timerid} {
	killutimer $timerid
	if {[set error [fconfigure $sock -error]] != ""} {
		close $sock
		putquick "PRIVMSG $chan :Koneksi ke $host \($port\) batal. \([string totitle $error]\)"
	} else {
		fileevent $sock writable {}
		fileevent $sock readable [list portcheck_read_pub $chan $sock $host $port]
		putquick "PRIVMSG $chan :Koneksi ke $host \($port\) diterima."
	}
}
proc portcheck_timeout_pub {chan sock host port} {
	close $sock
	putquick "PRIVMSG $chan :Koneksi ke $host \($port\) timed out."
}
proc portcheck_connected_join {nick chan sock host port timerid} {
	global portcheck_setting botnick
	killutimer $timerid
	if {[set error [fconfigure $sock -error]] != ""} {
		close $sock
	} else {
		fileevent $sock writable {}
		fileevent $sock readable [list portcheck_read_join $sock]
		if {$portcheck_setting(onotice)} {
			foreach i [chanlist $chan] {
				if {([isop $i $chan]) && ($i != $botnick)} {
					putserv "NOTICE $i :Port $port was found open on $nick's host. \($host\)"
				}
			}
		}
		if {$portcheck_setting(autoban_svr)} {
			putserv "MODE $chan +b *!*@$host"
			putserv "KICK $chan $nick :One of the ports open on your host is banned."
			timer $portcheck_setting(bantime) [list portcheck_unsvrban $chan $host]
		} elseif {$portcheck_setting(autoban_list)} {
			if {$portcheck_setting(global)} {
				newban *!*@$host PortCheck "One of the ports open on your machine is banned." $portcheck_setting(bantime)
			} else {
				newchanban $chan *!*@$host PortCheck "One of the ports open on your machine is banned." $portcheck_setting(bantime)
			}
		}
	}
}
proc portcheck_timeout_join {sock} {
	close $sock
}
proc portcheck_read_join {sock} {
	close $sock
}
proc portcheck_read_pub {sock} {
	global portcheck_setting
	if {!$portcheck_setting(read)} {
		close $sock
	} elseif {[gets $sock read] == -1} {
		putquick "PRIVMSG $chan :EOF On Connection To $host \($port\). Socket Closed."
		close $sock
	}
}
proc portcheck_unsvrban {chan host} {
	putserv "MODE $chan -b *!*@$host"
}
putlog "\002PORTCHECK:\002 PortCheck.tcl by terroris is loaded."

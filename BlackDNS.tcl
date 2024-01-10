#######################################################################################################
## BlackDNS.tcl 1.0  (05/10/2020)  			                  Copyright 2008 - 2018 @ WwW.TCLScripts.NET ##
##                        _   _   _   _   _   _   _   _   _   _   _   _   _   _                      ##
##                       / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \                     ##
##                      ( T | C | L | S | C | R | I | P | T | S | . | N | E | T )                    ##
##                       \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/                     ##
##                                                                                                   ##
##                                      ® BLaCkShaDoW Production ®                                   ##
##                                                                                                   ##
##                                              PRESENTS                                             ##
##									                                                                               ® ##
##########################################   BLACK DNS TCL   ##########################################
##									                                                                                 ##
##  DESCRIPTION: 							                                                                       ##
##  Next Generation of DNS TCL                                                                       ##
##    + now suporting multiple ip/hosts/nicks all in one command                                     ##
##    + shows the IPv4 ips and the IPv6 (if the server where the eggdrop is on supports it)          ##
##    + supports also reverse dns                                                                    ##
##    + command flood protection                                                                     ##
##                                                      							                               ##
##  Both IPv4 & IPv6 supported.                                                                      ##
##									                                                                                 ##
##  Tested on Eggdrop v1.8.4 (Debian Linux 3.16.0-4-amd64) Tcl version: 8.6.6                        ##
##									                                                                                 ##
#######################################################################################################
##									                                                                                 ##
##  INSTALLATION: 							                                                                     ##
##     ++ Edit the BlackDNS.tcl script and place it into your /scripts directory,                    ##
##     ++ add "source scripts/BlackDNS.tcl" to your eggdrop config and rehash the bot.               ##
##									                                                                                 ##
#######################################################################################################
##									                                                                                 ##
##  OFFICIAL LINKS:                                                                                  ##
##   E-mail      : BLaCkShaDoW[at]tclscripts.net                                                     ##
##   Bugs report : http://www.tclscripts.net                                                         ##
##   GitHub page : https://github.com/tclscripts/ 			                                             ##
##   Online help : irc://irc.undernet.org/tcl-help                                                   ##
##                 #TCL-HELP / UnderNet        	                                                     ##
##                 You can ask in english or romanian                                                ##
##									                                                                                 ##
##          Please consider a donation. Thanks!                                                      ##
##									                                                                                 ##
#######################################################################################################
##									                                                                                 ##
##                           You want a customised TCL Script for your eggdrop?                      ##
##                                Easy-peasy, just tell me what you need!                            ##
##                I can create almost anything in TCL based on your ideas and donations.             ##
##                  Email blackshadow@tclscripts.net or info@tclscripts.net with your                ##
##                    request informations and I'll contact you as soon as possible.                 ##
##									                                                                                 ##
#######################################################################################################
##									                                                                                 ##
##  To activate: .chanset +blackdns | from BlackTools: .set #channel +blackdns                       ##
##                                                                                                   ##
##  !dns [nick|IP|host] [nick|IP|host] .. - shows DNS or rDNS for IP/HOST/NICKs HOST.                 ##
##                                                                                                   ##
#######################################################################################################
##									                                                                                 ##
##  LICENSE:                                                                                         ##
##   This code comes with ABSOLUTELY NO WARRANTY.                                                    ##
##                                                                                                   ##
##   This program is free software; you can redistribute it and/or modify it under the terms of      ##
##   the GNU General Public License version 3 as published by the Free Software Foundation.          ##
##                                                                                                   ##
##   This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of          ##
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                                            ##
##   USE AT YOUR OWN RISK.                                                                           ##
##                                                                                                   ##
##   See the GNU General Public License for more details.                                            ##
##        (http://www.gnu.org/copyleft/library.txt)                                                  ##
##                                                                                                   ##
##  			          Copyright 2008 - 2020 @ WwW.TCLScripts.NET                        							 ##
##                                                                                                   ##
#######################################################################################################

#######################################################################################################
###                                CONFIGURATION FOR BlackDNS.TCL                                   ###
#######################################################################################################

###
# Cmdchar trigger
# - set here the trigger you want to use.
###
set dns(cmd_char) "!"

###
# set here who can execute the command (-|- for all)
###
set dns(use_flags) "-|-"

###
# FLOOD PROTECTION
#Set the number of minute(s) to ignore flooders, 0 to disable flood protection
###
set dns(ignore_prot) "1"

###
# FLOOD PROTECTION
#Set the number of requests within specifide number of seconds to trigger flood protection.
# By default, 4:10, which allows for upto 3 queries in 10 seconds. 4 or more quries in 10 seconds would cuase
# the forth and later queries to be ignored for the amount of time specifide above.
###
set dns(flood_prot) "4:10"

#######################################################################################################
###                       DO NOT MODIFY HERE UNLESS YOU KNOW WHAT YOU'RE DOING                      ###
#######################################################################################################

setudef flag blackdns


bind pub $dns(use_flags) $dns(cmd_char)dns dns:proc

proc dns:proc {nick host hand chan arg} {
  global dns
  set args [lrange [split $arg] 0 end]
if {![channel get $chan blackdns]} {
  return
}
set flood_protect [dns:flood:prot $chan $host]
if {$flood_protect == "1"} {
set get_seconds [dns:get:flood_time $host $chan]
  putserv "NOTICE $nick :\[DNS\] Flood protection enabled. Please wait \002$get_seconds\002 before using another command"
  return
}
if {$args == ""} {
  putserv "NOTICE $nick :\[DNS\] Error. Use !dns <nick/ip1/host1> <nick2/ip2/host2>.."
  return
}
  set nicks ""
  set hosts ""
foreach entry $args {
if {[string length $entry] == 0} {continue}
if {![regexp {[:\.]} $entry]} {
	lappend nicks $entry
  } else {
  set get_dns [dns:getdns $entry]
  show:dns $get_dns $entry $chan 0
    }
  }
if {$nicks != ""} {
  utimer 2 [list dns:nick $nick $chan $nicks 0]
  }
}

###
proc show:dns {get_dns entry chan type} {
  global dns
  set if_reverse [lindex $get_dns 0]
if {$if_reverse == 1} {
  lappend reverse_host [lindex $get_dns 1]
if {$type == 0} {
  putserv "PRIVMSG $chan :\[rDNS\] \002IP:\002 $entry ; \002Domain:\002 $reverse_host"
  } else {
  putserv "PRIVMSG $chan :\[rDNS\] \002NickName:\002 $type ; \002IP:\002 $entry ; \002Domain:\002 $reverse_host"
  }
} elseif {$get_dns == 0} {
if {$type == 0} {
  putserv "PRIVMSG $chan :\[DNS\] Could not resolve \002$entry\002"
} else {
  putserv "PRIVMSG $chan :\[DNS\] Could not resolve \002$entry\002 from \002$type\002"
          }
      } else {
  set ip_v4 [lindex $get_dns 0]
  set ip_v6 [lindex $get_dns 1]
if {$ip_v4 != "" && $ip_v6 != ""} {
      if {$type == 0} {
  putserv "PRIVMSG $chan :\[DNS\] \002HOST:\002 $entry ; \002IPv4:\002 [join $ip_v4 ", "] ; \002IPv6:\002 [join $ip_v6 ", "]"
  } else {
  putserv "PRIVMSG $chan :\[DNS\] \002NickName:\002 $type ; \002HOST:\002 $entry ; \002IPv4:\002 [join $ip_v4 ", "] ; \002IPv6:\002 [join $ip_v6 ", "]"
              }
      } elseif {$ip_v4 != ""} {
if {$type == 0} {
  putserv "PRIVMSG $chan :\[DNS\] \002HOST:\002 $entry ; \002IPv4:\002 [join $ip_v4 ", "]"
      } else {
  putserv "PRIVMSG $chan :\[DNS\] \002NickName:\002 $type ; \002HOST:\002 $entry ; \002IPv4:\002 [join $ip_v4 ", "]"
  }
      } elseif {$ip_v6 != ""} {
if {$type == 0} {
  putserv "PRIVMSG $chan :\[DNS\] \002HOST:\002 $entry ; \002IPv6:\002 [join $ip_v6 ", "]"
          } else {
  putserv "PRIVMSG $chan :\[DNS\] \002NickName:\002 $type ; \002HOST:\002 $entry ; \002IPv6:\002 [join $ip_v6 ", "]"
            }
        }
    }
}

###
proc dns:nick {nick chan nicks num} {
  global dns
  set current_nick [lindex $nicks $num]
  bind RAW - 302 dns:nick:raw
  putquick "USERHOST :$current_nick"
  set ::dnschan $chan
  set ::dnsnick $current_nick
  set incr [expr $num + 1]
if {[lindex $nicks $incr] != ""} {
  utimer 2 [list dns:nick $nick $chan $nicks $incr]
  }
}

###
proc dns:clear {} {
  global dns
  unbind RAW - 302 dns:nick:raw
  unset ::dnschan
  unset ::dnsnick
}

###
proc dns:nick:raw { from keyword arguments } {
  global dns
  set chan $::dnschan
  set dnsnick $::dnsnick
  set hosts [lindex [split $arguments] 1]
  set hostname [lindex [split $hosts "="] 1]
  regsub {^[-+]} $hostname "" mask
  set nickname [lindex [split $hosts "="] 0]
  regsub {^:} $nickname "" nick
  set mask [lindex [split $mask @] 1]
if {$nick == ""} {
  putserv "PRIVMSG $chan :\[DNS\] Error. $dnsnick is not online."
  dns:clear
  return 0
  }
  set get_dns [dns:getdns $mask]
  show:dns $get_dns $mask $chan $nick
  dns:clear
}

###
proc dns:getdns {ip} {
	global dns
	set ipv4 ""
	set ipv6 ""
  set host ""
  set status 0
	set gethost [catch {exec host $ip} results]
	set res [lrange [split $results] 0 end]
	set inc 0
	set llength [llength $res]
for {set i 0} { $i <= $llength} { incr i } {
	set word [lindex $res $i]
if {[string match -nocase "IPv6" $word]} {
	lappend ipv6 [join [lindex $res [expr $i + 2]]]
	}
if {[string match -nocase "*address*" $word] && ![string match -nocase "IPv6" [lindex $res [expr $i - 1]]]} {
	lappend ipv4 [join [lindex $res [expr $i + 1]]]
	}
if {[string match -nocase "domain" $word]} {
  set host [join [lindex $res [expr $i + 3]]]
  }
}
if {$ipv4 == "" && $ipv6 == "" && $host == ""} {
	return 0
	}
if {$host != ""} {
  return [list 1 $host]
}
	return [list $ipv4 $ipv6]
}


###
proc dns:flood:prot {chan host} {
	global dns
	set number [scan $dns(flood_prot) %\[^:\]]
	set timer [scan $dns(flood_prot) %*\[^:\]:%s]
if {[info exists dns(ipflood:$host:$chan:act)]} {
	return 1
}
foreach tmr [utimers] {
if {[string match "*dns:remove:flood $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
	}
}
if {![info exists dns(ipflood:$host:$chan)]} {
	set dns(ipflood:$host:$chan) 0
}
	incr dns(ipflood:$host:$chan)
	utimer $timer [list dns:remove:flood $host $chan]
if {$dns(ipflood:$host:$chan) > $number} {
	set dns(ipflood:$host:$chan:act) 1
	utimer [expr $dns(ignore_prot) * 60] [list dns:expire:flood $host $chan]
	return 1
	} else {
	return 0
	}
}

###
# Credits
###
set dns(projectName) "BlackDNS"
set dns(author) "BLaCkShaDoW"
set dns(website) "wWw.TCLScriptS.NeT"
set dns(email) "BLaCkShaDoW@TCLScriptS.NeT"
set dns(version) "v1.0 (IPv6 support)"


###
proc dns:remove:flood {host chan} {
	global dns
if {[info exists dns(ipflood:$host:$chan)]} {
	unset dns(ipflood:$host:$chan)
	}
}

###
proc dns:expire:flood {host chan} {
	global dns
if {[info exists dns(ipflood:$host:$chan:act)]} {
	unset dns(ipflood:$host:$chan:act)
	}
}

###
proc dns:get:flood_time {host chan} {
	global dns
		foreach tmr [utimers] {
if {[string match "*dns:expire:flood $host $chan*" [join [lindex $tmr 1]]]} {
	return [lindex $tmr 0]
		}
	}
}

putlog "\002$dns(projectName) $dns(version)\002 coded by\002 $dns(author)\002 ($dns(website)): Loaded & initialized.."

#######################
#######################################################################################################
###                 *** END OF BlackDNS TCL ***                                                     ###
#######################################################################################################

#############################################################################
## Cservice.tcl 1.0  (04/07/2020)  			                        				   ##
##                                                                         ##
##                              Copyright 2008 - 2020 @ WwW.TCLScripts.NET ##
##         _   _   _   _   _   _   _   _   _   _   _   _   _   _           ##
##        / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \          ##
##       ( T | C | L | S | C | R | I | P | T | S | . | N | E | T )         ##
##        \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/          ##
##                                                                         ##
##                       ® BLaCkShaDoW Production ®                        ##
##                                                                         ##
##                                PRESENTS                                 ##
##									                                     								 ® ##
#############################   CSERVICE TCL   ##############################
##									                                      								 ##
##  DESCRIPTION: 							                            							   ##
##  Gets information about registered channels on undernet via             ##
## https://cservice.undernet.org/ like channel registered time,            ##
## created time and other more if the user specified in tcl has access to  ##
## that channel. It can also list users that have access to channel.			 ##
##																																				 ##
##  Tested on Eggdrop v1.8.4 (Debian Linux) Tcl version: 8.6.9             ##
##									                                       								 ##
#############################################################################
##								                                   							         ##
##  INSTALLATION: 						                                   					 ##
##  ++ http, tls packages are REQUIRED for this script to work.     			 ##
##  ++ Edit cservice.tcl script & place it into your /scripts directory.   ##
##  ++ add "source scripts/cservice.tcl" to your eggdrop.conf & rehash.    ##
##																																				 ##
##  CONFIGURATION																													 ##
##  ++ put Xusername and Xpassword in tcl bellow													 ##
##								                                           							 ##
#############################################################################
##									                                      								 ##
##  OFFICIAL LINKS:                                                        ##
##   E-mail      : BLaCkShaDoW[at]tclscripts.net                           ##
##   Bugs report : http://www.tclscripts.net                               ##
##   GitHub page : https://github.com/tclscripts/ 			              	   ##
##   Online help : irc://irc.undernet.org/tcl-help                         ##
##                 #TCL-HELP / UnderNet        	                           ##
##                 You can ask in english or romanian                      ##
##									                                      								 ##
##     paypal.me/DanielVoipan = Please consider a donation. Thanks!        ##
##									                                    								   ##
#############################################################################
##									                                      								 ##
##           You want a customised TCL Script for your eggdrop?            ##
##               Easy-peasy, just tell me what you need!                   ##
##  I can create almost anything in TCL based on your ideas and donations. ##
##    Email blackshadow@tclscripts.net or info@tclscripts.net with your    ##
##      request informations and I'll contact you as soon as possible.     ##
##									                                     								   ##
#############################################################################
##								                                      							     ##
##  COMMANDS:                                                              ##
##								                                          							 ##
##  To activate:                                                           ##
##  .chanset +cs | from BlackTools: .set #channel +cs        							 ##
##                                                                         ##
##  Setup language:																												 ##
##  .chanset +cs-lang <en/ro>																						 	 ##
##																																				 ##
##  !cs #channel                   																			   ##
##                                                                         ##
##  !cs-acc #channel (list all users that have access)										 ##
##                                                                         ##
##  !cs-acc #channel [user] (list only users that match, accepts keywords)##
##								                                          							 ##
##  !cs-acc #channel [access level] (list users that have this access)    ##
##								                                          							 ##
#############################################################################
##								                                     							       ##
##  PERSONAL AND NON-COMMERCIAL USE LIMITATION.                            ##
##                                                                         ##
##  This program is provided on an "as is" and "as available" basis,       ##
##  with ABSOLUTELY NO WARRANTY. Use it at your own risk.                  ##
##                                                                         ##
##  Use this code for personal and NON-COMMERCIAL purposes ONLY.           ##
##                                                                         ##
##  Unless otherwise specified, YOU SHALL NOT copy, reproduce, sublicense, ##
##  distribute, disclose, create derivatives, in any way ANY PART OF       ##
##  THIS CONTENT, nor sell or offer it for sale.                           ##
##                                                                         ##
##  You will NOT take and/or use any screenshots of this source code for   ##
##  any purpose without the express written consent or knowledge of author.##
##                                                                         ##
##  You may NOT alter or remove any trademark, copyright or other notice   ##
##  from this source code.                                                 ##
##                                                                         ##
##              Copyright 2008 - 2020 @ WwW.TCLScripts.NET                 ##
##                                                                         ##
#############################################################################

#############################################################################
##                              CONFIGURATIONS                             ##
#############################################################################
###
#First char for cs command
set cservice(first_char) "!"

###
#Flags needed to use !cs , !cs-acc
set cservice(flags) "-|-"

###
#Set website username
set cservice(username) "arab"

###
#Set website password
set cservice(password) "mofo1234"

###
#Set default script language (EN/RO)
set cservice(language) "EN"

##
#How many entries to show per page for "cs-acc <#channel>" ? (access list command)
set cservice(max_entries) "3"

###
# FLOOD PROTECTION
#Set the number of requests within specifide number of seconds to trigger flood protection.
# By default, 3:10, which allows for upto 3 queries in 10 seconds. 3 or more quries in 10 seconds would cuase
# the forth and later queries to be ignored for the amount of time specifide above.
###
set cservice(flood_prot) "3:10"

###
# FLOOD PROTECTION
#Set the number of minute(s) to ignore flooders, 0 to disable flood protection
###
set cservice(ignore_prot) "1"

################################################################################
###            DO NOT MODIFY HERE UNLESS YOU KNOW WHAT YOU'RE DOING          ###
################################################################################

bind pub $cservice(flags) $cservice(first_char)cs cservice:channel_info
bind pub $cservice(flags) $cservice(first_char)cs-acc cservice:channel_access

###
setudef str cs-lang
setudef flag cs

###
package require http
package require tls

###
proc cservice:login {} {
	global cservice
	http::register https 443 [list ::tls::socket -autoservername true]
  set query [::http::formatQuery username $cservice(username) password $cservice(password)]
	set link "https://cservice.undernet.org/login.php?$query"
	set logintoken [http::geturl $link -headers {Content-Type: text/html} -timeout 50000]
	upvar \#0 $logintoken state
	set cookielist [list]
foreach {key value} $state(meta) {
if {[string equal -nocase $key "Set-Cookie"]} {
        lappend cookielist [lindex [split $value ";"] 0]
    		}
	}
	http::cleanup $logintoken
	return $cookielist
}

###
proc cservice:specialtext {string} {
    set map {}
    foreach {entity number} [regexp -all -inline {&#(\d+)} $string] {
        lappend map $entity [format \\u%04x [scan $number %d]]
    }
    set string [string map [subst -nocomm -novar $map] $string]
	return $string
 }

###
proc cservice:channel_access {nick host hand chan arg} {
	global cservice
	if {![channel get $chan cs]} {
		return
	}
	set flood_protect [cservice:flood:prot $chan $host]
if {$flood_protect == "1"} {
	return
}
	set channel [lindex [split $arg] 0]
	set search_user [lindex [split $arg] 1]
	set arg [split $arg]
if {$channel == ""} {
  cservice:say $nick $chan 2 "" 0
  return
  }
	set query [::http::formatQuery name $channel]
	set link "https://cservice.undernet.org/channels.php?$query"
	set data [cservice:data $link 0]
if {[string match -nocase "*That channel does not exist*" $data]} {
	cservice:say $nick $chan 3 "" 0
	return
}
if {[string match -nocase "*Sorry, you can't view details of that channel.*" $data]} {
	cservice:say $nick $chan 4 "" 0
	return
}
	regexp {<td colspan=7>(.*)} $data -> data
	regsub -all {<td colspan=6>(.*)} $data "" data
	set split_data [split $data "\n"]
	array set itemlist [list]
	set j 0
	set start 0
	set end 0
	set inc 0
foreach line $split_data {
	incr j
if {[regexp {<tr bgcolor=\#ffffff>} $line] || [regexp {<tr bgcolor=#ff0000>} $line]} {
	set start $j
	incr inc
	lappend itemlist($inc) $start
	continue
		}
if {([regexp {</tr>} $line] || [regexp {</tr></table> <br><br>} $line]) && $start != "0"} {
	set end $j
	lappend itemlist($inc) $end
	continue
		}
	}
if {[array size itemlist] == 0} {
	cservice:say $nick $chan 5 "" 1
	}
		set users ""
	foreach item [lsort -integer -increasing [array names itemlist]] {
		incr counter
		set b [lindex $itemlist($item) 0]
		set c [lindex $itemlist($item) 1]
if {[info exists user]} { unset user }
if {[info exists access]} {unset access}
if {[info exists suspended]} {unset suspended}
	set autoop 0
	set autovoice 0
	set autoinvite 0
for {set i $b} {$i <= $c} { incr i} {
if {![info exists user]} {
	regexp {<td valign=top><font size=-1><a href="(.*)">(.*)</a></td><td valign=top align=center>} [lindex $split_data $i] string user_link user
if {[info exists user]} { continue }
	}
if {![info exists access]} {
	regexp {<font size=-1>(.*)</td>} [lindex $split_data $i] -> access
	}
if {$autoop == 0} {
	set autoop [regexp {<td valign=top align=center><img src="images\/inuse\.gif" alt="\[@\]">(.*)} [lindex $split_data $i]]
	}
if {$autovoice == 0} {
	set autovoice [regexp {<td valign=top align=center><img src="images/inuse\.gif" alt="\[\+\]"></td>} [lindex $split_data $i]]
	}
if {$autoinvite == 0} {
	set autoinvite [regexp {<td valign=top align=center><img src="images/inuse\.gif" alt="\[\+\]">$} [lindex $split_data $i]]
	}
if {![info exists suspended]} {
	regexp {<td valign=top align=left><font size=-2>(.*)</font></td>} [lindex $split_data $i] -> suspended
	}
}
if {[info exists user]} {
		set access [string map {"<b>" ""
													"</b>" ""} $access]
if {[info exists suspended]} {
if {$search_user != ""} {
if {[string match -nocase $search_user $user] || [string equal -nocase $search_user $access]} {
	lappend users [list $user $access $autoop $autovoice $autoinvite [string map {"<br>" ""} $suspended]]
	}
} else {
	lappend users [list $user $access $autoop $autovoice $autoinvite [string map {"<br>" ""} $suspended]]
}
			} else {
if {$search_user != ""} {
if {[string match -nocase $search_user $user] || [string equal -nocase $search_user $access]} {
	lappend users [list $user $access $autoop $autovoice $autoinvite ""]
					}
				} else {
	lappend users [list $user $access $autoop $autovoice $autoinvite ""]
				}
			}
		}
	}
if {$users == ""} {
	cservice:say $nick $chan 5 "" 1
	return
}
if {![info exists cservice($host:show)]} {
if {$search_user != ""} {
	cservice:say $nick $chan 6 [list $channel $search_user] 1
} else {
	cservice:say $nick $chan 6 [list $channel "ALL"] 1
}
  set llength [llength $users]
  set cservice($host:show) [list $llength 0 $arg $users]
} else {
  set old_arg [lindex $cservice($host:show) 2]
if {$old_arg != $arg} {
if {$search_user != ""} {
		cservice:say $nick $chan 6 [list $channel $search_user] 1
	} else {
		cservice:say $nick $chan 6 [list $channel "ALL"] 1
	}
  set llength [llength $users]
  set cservice($host:show) [list $llength 0 $arg $users]
  } else {
  set users [lindex $cservice($host:show) 3]
  	}
	}
	cservice:users $nick $host $users $arg $channel $chan
}

###
proc cservice:users {nick host data arg channel chan} {
		global cservice
		set flood_protect [cservice:flood:prot $chan $host]
if {$flood_protect == "1"} {
		return
}
		set num_total [lindex $cservice($host:show) 0]
		set total_show [lindex $cservice($host:show) 1]
if {$num_total > $cservice(max_entries)} {
	set show_items $cservice(max_entries)
	set num_left [expr $num_total - $cservice(max_entries)]
	set cservice($host:show) [list $num_left [expr $total_show + $show_items] $arg $data]
if {$num_left == 0} {
	unset cservice($host:show)
}
	cservice:show_users $nick $host $data $show_items $num_left $total_show $channel $chan
} elseif {$num_total == $cservice(max_entries)} {
	set show_items $cservice(max_entries)
	set num_left 0
	cservice:show_users $nick $host $data $show_items $num_left $total_show $channel $chan
if {[info exists cservice($host:show)]} {
	unset cservice($host:show)
	}
} else {
	set show_items $num_total
	set num_left 0
if {[info exists cservice($host:show)]} {
		unset cservice($host:show)
		}
	cservice:show_users $nick $host $data $show_items $num_left $total_show $channel $chan
	}
}

###
proc cservice:show_users {nick host data num num_left total_show channel chan} {
		global cservice
		set counter 0
		set lang [cservice:lang $chan]
		set show $total_show
while {$counter < $num} {
		set line [lindex $data $show]
    set username [lindex $line 0]
    set access [lindex $line 1]
		set autoop [lindex $line 2]
    set autovoice [lindex $line 3]
    set autoinvite [lindex $line 4]
    set suspended [lindex $line 5]
		set yes [cservice:specialtext "&#10004"]
		set no [cservice:specialtext "&#10008"]
	if {$autoop == 0} {set autoop $no} else {set autoop $yes}
	if {$autovoice == 0} {set autovoice $no} else {set autovoice $yes}
	if {$autoinvite == 0} {set autoinvite $no} else {set autoinvite $yes}
	if {$suspended == ""} {set suspended $no}
    set replace(%msg.1%) $username
		set replace(%msg.2%) $access
		set replace(%msg.3%) $autoop
		set replace(%msg.4%) $autovoice
		set replace(%msg.5%) $autoinvite
		set replace(%msg.6%) $suspended
		set output [string map [array get replace] $cservice(lang.$lang.7)]
		putserv "NOTICE $nick :$output"
		incr counter
		set show [expr $show + 1]
	}
	if {$num_left > 0} {
	set replace(%msg.1%) $num_left
	set replace(%msg.2%) $channel
	set output [string map [array get replace] $cservice(lang.$lang.8)]
	putserv "NOTICE $nick :$output"
	cservice:save_list $host
	} else {
	set replace(%msg.1%) $channel
	set output [string map [array get replace] $cservice(lang.$lang.9)]
	putserv "NOTICE $nick :$output"
	}
}

###
proc cservice:save_list {host} {
	global cservice
	foreach tmr [utimers] {
	if {[string match "*cservice:unset_list $host*" [join [lindex $tmr 1]]]} {
		killutimer [lindex $tmr 2]
			}
		}
		utimer 60 [list cservice:unset_list $host]
	}

###
proc cservice:unset_list {host} {
	global cservice
if {[info exists cservice($host:show)]} {
		unset cservice($host:show)
	}
}

###
proc cservice:channel_info {nick host hand chan arg} {
  global cservice
if {![channel get $chan cs]} {
			return
}
  set channel [lindex [split $arg] 0]
if {$channel == ""} {
  cservice:say $nick $chan 2 "" 0
  return
  }
  set query [::http::formatQuery name $channel]
  set link "https://cservice.undernet.org/channels.php?$query"
  set data [cservice:data $link 0]
if {[string match -nocase "*That channel does not exist*" $data]} {
	cservice:say $nick $chan 3 "" 0
	return
}
if {[string match -nocase "*Sorry, you can't view details of that channel.*" $data]} {
	cservice:say $nick $chan 4 "" 0
	return
}
	regexp {<html><head><title>.</title><style type=text/css>(.*)} $data -> data
	regsub -all {<td colspan=7>(.*)} $data "" data
	set split_data [split $data "\n"]
	set channel_set_autojoin ""
	set mass_deop_protection ""
	set flood_protection ""
	set channel_homepage ""
	set channel_description ""
	set channel_keywords ""
	set channel_saved_mode ""
	set channel_registered_on ""
	set channel_created_on ""
	set channel_lastchange_on ""
	set no_access 0
if {[string match -nocase "*You don't have access to this channel*" $data]} {
	set no_access 1
}
foreach line $split_data {
	regexp {Auto Join <img src="images/inuse.gif" ALT="(.*)"><br>} $line -> channel_set_autojoin
	regexp {<b>Mass Deop Protection:</b> (.*)<br>} $line -> mass_deop_protection
	regsub -all {<br>(.*)} $mass_deop_protection "" mass_deop_protection
	regexp {<b>Flood Protection:</b>(.*)<br>} $line -> flood_protection
	regsub -all {<br>(.*)} $flood_protection "" flood_protection
	regexp {<b>Channel Homepage: </b><a href="(.*)" target="_blank">(.*)</a><br>} $line string channel_homepage
	regexp {b>Description: </b>(.*)<br>} $line -> channel_description
	regexp {b>Keywords:</b>(.*)<br>} $line -> channel_keywords
	regsub -all {<br>(.*)} $channel_keywords "" channel_keywords
	regexp {<b>Saved channel mode:</b>(.*)<br>} $line -> channel_saved_mode
	regsub -all {<br>(.*)} $channel_saved_mode "" channel_saved_mode
	regexp {<b>Registered on</b></td><td><font size=-1>(.*)</td></tr>} $line -> channel_registered_on
	regexp {<b>Channel Created:</b></td><td><font size=-1>(.*)</td></tr>} $line -> channel_created_on
	regexp {<b>Last Change:</b></td><td><font size=-1>(.*)</td></tr>} $line -> channel_lastchange_on
	}
	if {[string equal -nocase [concat $channel_set_autojoin] "Yes"]} {
	set channel_set_autojoin [cservice:specialtext "&#10004"]
} else {
	set channel_set_autojoin [cservice:specialtext "&#10008"]
}
	if {$channel_homepage == "http://'" || $channel_homepage == ""} {set channel_homepage "N/A"}
	if {[concat $channel_keywords] == ""} {set channel_keywords "N/A"}
	if {[concat $channel_description] == ""} { set channel_description "N/A"}
	if {$no_access == 0} {
		set output [list $channel [concat $channel_registered_on] [concat $channel_created_on] [concat $channel_description] [concat $channel_homepage] [concat $channel_keywords] [concat $channel_saved_mode] [concat $flood_protection] [concat $mass_deop_protection] [concat $channel_set_autojoin] [concat $channel_lastchange_on]]
		cservice:say $nick $chan 1 $output 0
		cservice:say $nick $chan 11 [list $cservice(first_char) $channel] 0
	} else {
		set output [list $channel [concat $channel_registered_on] [concat $channel_created_on] [concat $channel_lastchange_on]]
		cservice:say $nick $chan 10 $output 0
		cservice:say $nick $chan 11 [list $cservice(first_char) $channel] 0
	}
}


###
proc cservice:say {nick chan type string output_type} {
	global cservice
	set lang [cservice:lang $chan]
	set counter 0
	foreach w $string {
		incr counter
		set replace(%msg.$counter%) $w
	}
		set output [string map [array get replace] $cservice(lang.$lang.$type)]
if {$output_type == 0} {
		putserv "PRIVMSG $chan :$output"
	} else {
		putserv "NOTICE $nick :$output"
	}
}

###
proc cservice:lang {chan} {
	global cservice
	set lang [channel get $chan cs-lang]
if {$lang == ""} {
		set lang $cservice(language)
	} elseif {![info cservice(lang.$lang.1)]} {
		set lang $cservice(language)
	}
	set lang [string tolower $lang]
	return $lang
}

###
proc cservice:data {link cookie} {
  global cservice
  set ipq [http::config -useragent "lynx"]
	http::register https 443 [list ::tls::socket -autoservername true]
if {$cookie == 1} {
  set cookies [cservice:login]
  set cservice(cookies) $cookies
  set ipq [::http::geturl "$link" -headers [list Cookie [join $cookies ";"]]]
} else {
if {[info exists cservice(cookies)]} {
	set ipq [::http::geturl "$link" -headers [list Cookie [join $cservice(cookies) ";"]]]
} else {
	set ipq [::http::geturl "$link" -timeout 5000]
	}
}
  set status [::http::status $ipq]
if {$status != "ok"} {
::http::cleanup $ipq
return 0
}
  set data [http::data $ipq]
  ::http::cleanup $ipq
if {$data == ""} {
  cservice:data $link 1
} else {
return $data
  }
}

###
proc cservice:flood:prot {chan host} {
	global cservice
	set number [scan $cservice(flood_prot) %\[^:\]]
	set timer [scan $cservice(flood_prot) %*\[^:\]:%s]
if {[info exists cservice(flood:$host:$chan:act)]} {
	return 1
}
foreach tmr [utimers] {
if {[string match "*cservice:remove:flood $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
	}
}
if {![info exists cservice(flood:$host:$chan)]} {
	set cservice(flood:$host:$chan) 0
}
	incr cservice(flood:$host:$chan)
	utimer $timer [list cservice:remove:flood $host $chan]
if {$cservice(flood:$host:$chan) > $number} {
	set cservice(flood:$host:$chan:act) 1
	utimer [expr $cservice(ignore_prot) * 60] [list cservice:expire:flood $host $chan]
	return 1
	} else {
	return 0
	}
}
set cservice(projectName) "Cservice.tcl"
set cservice(author) "BLaCkShaDoW"
set cservice(website) "wWw.TCLScriptS.NeT"
set cservice(email) "blackshadow\[at\]tclscripts.net"
set cservice(version) "v1.0"
###
proc cservice:remove:flood {host chan} {
	global cservice
if {[info exists cservice(flood:$host:$chan)]} {
	unset cservice(flood:$host:$chan)
	}
}

###
proc cservice:expire:flood {host chan} {
	global cservice
if {[info exists cservice(flood:$host:$chan:act)]} {
	unset cservice(flood:$host:$chan:act)
	}
}

##English language
		set cservice(lang.en.1) "Cservice Channel \002%msg.1%\002 -- Registered on: %msg.2% ; Created on: %msg.3% ; Description: %msg.4% ; HomePage: %msg.5% ; Keywords: %msg.6% ; Saved modes: %msg.7% ; Flood prot: %msg.8% ; MassDeop: %msg.9% ; Autojoin: %msg.10% ; Last change: %msg.11%"
		set cservice(lang.en.2) "Channel not specified."
		set cservice(lang.en.3) "That channel does not exist."
		set cservice(lang.en.4) "Sorry, you can't view details of that channel."
		set cservice(lang.en.5) "No users that have access that match the criteria."
		set cservice(lang.en.6) "Cservice Channel \002%msg.1%\002 -- %msg.2%"
		set cservice(lang.en.7) "\002Username:\002 %msg.1% ; \002Access level:\002 %msg.2% ; \002Autoop:\002 %msg.3% ; \002Autovoice:\002 %msg.4% ; \002AutoInvite:\002 %msg.5% ; \002Access suspended:\002 %msg.6%."
		set cservice(lang.en.8) "%msg.1% users left for channel %msg.2%, type again the command."
		set cservice(lang.en.9) "End of users list for channel %msg.1%."
		set cservice(lang.en.10) "Cservice Channel \002%msg.1%\002 -- Registered on: %msg.2% ; Created on: %msg.3% ; Last change: %msg.4%"
		set cservice(lang.en.11) "Use %msg.1%cs-acc %msg.2% to view access list."
##Romanian language
	set cservice(lang.ro.1) "Canal Cservice \002%msg.1%\002 -- Inregistrat in: %msg.2% ; Creat in: %msg.3% ; Descriere: %msg.4% ; Pagina Web: %msg.5% ; Cuvinte cheie: %msg.6% ; Moduri salvate: %msg.7% ; Prot flood: %msg.8% ; MassDeop: %msg.9% ; AutoIntrare: %msg.10% ; Ultima schimbare: %msg.11%"
	set cservice(lang.ro.2) "Canalul nu a fost specificat."
	set cservice(lang.ro.3) "Canalul specificat nu exista."
	set cservice(lang.ro.4) "Imi pare rau, nu poti vizualiza detalii despre acest canal."
	set cservice(lang.ro.5) "Nu sunt useri care au access ce se potrivesc criteriilor."
	set cservice(lang.ro.6) "Canal Cservice \002%msg.1%\002 -- Toti utilizatorii"
	set cservice(lang.ro.7) "\002Utilizator:\002 %msg.1% ; \002Nivel access:\002 %msg.2% ; \002Autoop:\002 %msg.3% ; \002Autovoice:\002 %msg.4% ; \002Auto invitatie:\002 %msg.5% ; \002Access suspendat:\002 %msg.6%."
	set cservice(lang.ro.8) "%msg.1% useri ramasi pentru canalul %msg.1%, te rog scrie din nou comanda."
	set cservice(lang.ro.9) "Sfarsit lista useri pentru canalul %msg.1%."
	set cservice(lang.ro.10) "Canal Cservice \002%msg.1%\002 -- Inregistrat in: %msg.2% ; Creat in: %msg.3% ; Ultima schimbare: %msg.4%"
	set cservice(lang.ro.11) "Foloseste %msg.1%cs-acc %msg.2% pentru a vizualiza lista de accese."

	putlog "\002$cservice(projectName) $cservice(version)\002 coded by\002 $cservice(author)\002 ($cservice(website)): Loaded & initialised.."

##################
#######################################################################################################
###                 				  *** END OF Cservice TCL ***                                           ###
#######################################################################################################

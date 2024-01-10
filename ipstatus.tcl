############################################################################
# IPStatus 1.1
# - pings a given destination (IPv4, IPv6 or website) and replies ping time and if is up or down. 
#
# ATTENTION!!! IPv6 reply works only for those who have IPv6 active on their machine!!
#
# USAGE: !iping <ip> / <host> / <website>
#
# UPDATES/CHANGES:
# - Supports IPv6 (only for those who have ipv6 active on their machine!!)
# - Multi-language support
#
# To activate .chanset #channel +ipstatus | BlackTools : .set +ipstatus
# 
# To chose a different language .set ipslang <RO> / <EN> / <IT>
#
#                       BLaCkShaDoW ProductionS
#      _   _   _   _   _   _   _   _   _   _   _   _   _   _  
#     / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ 
#    ( t | c | l | s | c | r | i | p | t | s | . | n | e | t )
#     \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/
#                                    #TCL-HELP @ Undernet.org
#     
##########################################################################################

###
# Set here who can execute the command (-|- for all)
###
set iping_flags "mno|M"

###
# Cmdchar trigger
# +++ change cmdchar to the trigger you want to use.
###
set iping(cmdchar) "!"

###
# Bindings
# - using commands
###
bind pub $iping_flags $iping(cmdchar)iping ipstatus

###
# Language setting
# - what language you want to receive the info data ( RO / EN / IT )
#
# - to set script language:
# .set ipslang <ro/en/it> or .chanset #channel ipslang <ro/en/it>
#
###
set ipstatus(default_lang) "RO"

###
# Channel flags
# - to activate the script: 
# .set +ipstatus or .chanset #channel +ipstatus
#
###
setudef flag ipstatus
setudef str ipslang

############################################################################

###
# Functions
# Do NOT touch unless you know what you are doing
###

proc ipstatus {nick host hand chan arg} {
	set offline 0
	set online 0
	set time 0
	set package_lost 0
	set no_serv 0
if {![channel get $chan ipstatus]} {
	return
}
	set ip [lindex [split $arg] 0]
if {$ip == ""} {
	ipstatus:tell $nick $chan 1 none
	return
}
	set check_ipv6 [regexp {^([0-9A-Fa-f]{0,4}:){2,7}([0-9A-Fa-f]{1,4}$|((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4})$} $ip]
if {$check_ipv6 == "1"} {	
	set check_ping [catch {exec ping6 -c1 $ip 2>/dev/null} results]
} else {
	set check_ping [catch {exec ping -c1 $ip 2>/dev/null} results]
}

	set split_text [split [lrange $results 0 end] " "]
foreach text $split_text {
if {[string equal -nocase $ip $text]} {
	set no_serv 1
} elseif {[string match -nocase "0%" $text] || [string match -nocase "0.0%" $text]} {
	set online 1
} elseif {[string match -nocase "100%" $text] || [string match -nocase "100.0%" $text]} {
	set offline 1
} elseif {[string match -nocase "%" $text]} {
	set package_lost $text
} elseif {[string match -nocase "time=*" $text]} {
	set time $text
		}
	}
if {$no_serv != "0"} {
if {$online != "0"} {
	set split_time [split $time "="]
	set time [lindex $split_time 1]
	ipstatus:tell $nick $chan 2 "$ip~$time"
	}
if {$offline != "0"} {
	ipstatus:tell $nick $chan 3 "$ip~0"
	}
}
if {$offline == "0" && $online == "0" || $no_serv == "0"} {
if {$no_serv == "0"} { set time 0 }
	ipstatus:tell $nick $chan 4 "$ip~$package_lost~$time"
	}
}

proc ipstatus:getlang {chan} {
	global black ipstatus
	set getlang [string tolower [channel get $chan ipslang]]
if {$getlang == ""} {
	set lang $ipstatus(default_lang)
} else {
if {[info exists black(iping.$getlang.1)]} {
	set lang $getlang
} else { 
	set lang $ipstatus(default_lang)
		}
	}
	return [string tolower $lang]
}


proc ipstatus:tell {nick chan type arg} {
	global black ipstatus
	set arg_s [split $arg "~"]
	set inc 0
foreach s $arg_s {
	set inc [expr $inc + 1]
	set replace(%msg.$inc%) $s
}
	set getlang [ipstatus:getlang $chan]

if {[info exists black(iping.$getlang.$type)]} {
	set reply [string map [array get replace] $black(iping.$getlang.$type)]
if {$type == "1"} {
	putserv "NOTICE $nick :$reply"
	return	
		}
	putserv "PRIVMSG $chan :$reply"
	}
}

set ipstatus(projectName) "IPStatus"
set ipstatus(author) "BLaCkShaDoW"
set ipstatus(website) "wWw.TCLScriptS.NeT"
set ipstatus(version) "v1.1"

#LANGUAGES

#Romanian

set black(iping.ro.1) "\[IPing\] Foloseste: \002!iping\002 <ip> / <\002host\002> / <website>"
set black(iping.ro.2) "\002Destinatie\002: %msg.1% | \002Status\002:\0033 ONLINE\003 | \002response PING\002: %msg.2% ms"
set black(iping.ro.3) "\002Destinatie\002: %msg.1% | \002Status\002:\0034 OFFLINE\003 | \002response PING\002: %msg.2% ms"
set black(iping.ro.4) "\002Destinatie\002: %msg.1% | \002Status\002:\00314 INACCESIBILA\003 (%msg.2% pachete pierdute) | \002response PING\002: %msg.3% ms"

#English

set black(iping.en.1) "\[IPing\] Usage: \002!iping\002 <ip> / <\002hostname\002> / <website>"
set black(iping.en.2) "\002Destination\002: %msg.1% | \002Status\002:\0033 ONLINE\003 | \002PING Reply\002: %msg.2% ms"
set black(iping.en.3) "\002Destination\002: %msg.1% | \002Status\002:\0034 OFFLINE\003 | \002PING Reply\002: %msg.2% ms"
set black(iping.en.4) "\002Destination\002: %msg.1% | \002Status\002:\00314 UNREACHABLE\003 (%msg.2% packet loss) | \002PING Reply\002: %msg.3% ms"

#Italian

set black(iping.it.1) "\[IPing\] Uso: \002!iping\002 <ip> / <\002hostname\002> / <sitoweb>"
set black(iping.it.2) "\002Destinazione\002: %msg.1% | \002Stato\002:\0033 ONLINE\003 | \002PING Rispondi\002: %msg.2% ms"
set black(iping.it.3) "\002Destinazione\002: %msg.1% | \002Stato\002:\0034 OFFLINE\003 | \002PING Rispondi\002: %msg.2% ms"
set black(iping.it.4) "\002Destinazione\002: %msg.1% | \002Stato\002:\00314 IRRAGGIUNGIBILE\003 (%msg.2% pacchetti persi) | \002PING Rispondi\002: %msg.3% ms"

#Spanish

set black(iping.es.1) "\[IPing\] Uso: \002!iping\002 <ip> / <\002hostname\002> / <sitioweb>"
set black(iping.es.2) "\002Destino\002: %msg.1% | \002Estado\002:\0033 ONLINE\003 | \002PING Respuesta\002: %msg.2% ms"
set black(iping.es.3) "\002Destino\002: %msg.1% | \002Estado\002:\0034 OFFLINE\003 | \002PING Respuesta\002: %msg.2% ms"
set black(iping.es.4) "\002Destino\002: %msg.1% | \002Estado\002:\00314 INALCANZABLE\003 (%msg.2% paquetes perdidos) | \002PING Respuesta\002: %msg.3% ms"

putlog "\002$ipstatus(projectName) $ipstatus(version)\002 coded by $ipstatus(author) ($ipstatus(website)): Loaded."

##############
##########################################################
##   END                                                 #
##########################################################

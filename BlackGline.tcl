##########################################################################
#
# BlackGline 1.0
#
#This TCL shows information about IPS who have gline on undernet.
#-The creation date , the reason of the Gline , the date when the Gline will
#expire.
#
#To activate type .chanset #canal +blackgline
#
#The command is - !gline <ip>
#
#                                             BLaCkShaDoW ProductionS
##########################################################################

#Seteaza aici flagurile care pot folosii comanda !gline <ip>

set flags "nm|MNSmnO"

##########################################################################

bind pub $flags !gline getgline
setudef flag blackgline

proc getgline {nick host hand chan arg} {
global botnick
set ip [lindex [split $arg] 0]
set ::gchan $chan
if {[channel get $chan blackgline]} {
if {$ip == ""} { puthelp "NOTICE $nick :Use !gline <ip> ( example : 192.168.0.1 )"
return 0
}
putquick "GLINE $ip"
bind raw - 280 isgline
bind raw - 512 nogline
}
}

proc isgline { from keyword arguments } {
set chan $::gchan
set ip [lindex [split $arguments] 1]
set fgline [lindex [split $arguments] 4]
set egline [lindex [split $arguments] 3]
set reason [join [lrange [split $arguments] 7 end]]
puthelp "PRIVMSG $chan :Gline for $ip"
puthelp "PRIVMSG $chan :This G-Line was created on :[ctime $egline] , with the reason $reason"
puthelp "PRIVMSG $chan :It will expire on :[ctime $fgline]"
unbind raw - 280 isgline
}

proc nogline { from keyword arguments } {
set chan $::gchan
puthelp "PRIVMSG $chan :There arent any gline for this IP."
unbind raw - 512 nogline
}

putlog "BlackGline Tcl 1.0 by BLaCkShaDoW Loaded"

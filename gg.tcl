# Auto MSG To Chan
# +Author  : Dorin
# +Email   : contact@ircstar.org
# +Website : wWw.IRCStar.Org

# Set your channel
 
set send_chans "#pentest" 

# Set Timer one line after X mins

set send_time "60"

# Set Your Messages. You can insert more messages caz is every X min an random message from the list..

set send_msg {
"ULTRA-NEW: ultra-banner now supports proxy.lst (SOCKS5:IP:PORT)"
}

#########################################
#!!!!!!DO NOT EDIT AFTER THIS LINE!!!!!!#
#########################################

if {![string match "*time_send*" [timers]]} {
 timer $send_time time_send
}

proc time_send {} {
 global send_msg send_chans send_time
 if {$send_chans == "*"} {
  set send_temp [channels]
 } else {
  set send_temp $send_chans
 }
 foreach chan $send_temp {
  set send_rmsg [lindex $send_msg [rand [llength $send_msg]]]
 puthelp "PRIVMSG $chan :$send_rmsg" 
timer $send_time time_send
return 1
 }
 }


putlog "Auto MSG By Dorin @ IRCStar.Org Loaded"

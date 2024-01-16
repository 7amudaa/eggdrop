#-------------------------------------------------
#remind.tcl 1.0 written by dre^ @ EFnet on 7.22.00
#-------------------------------------------------
#Have you ever been on IRC and wished you had a little alarm
#clock built right into your bot? Well, now you do. This is a
#very simple script that will remind you about something after
#an interval of your choosing. The command syntax is as follows:
#  /msg <botname> remind <minutes> <text>  for example...
#  /msg MyBot remind 30 Call yo momma! 
#Upon issuing a reminder command, your reminder will be confirmed.
#The script will also track nick changes, so you won't lose a
#reminder if you change nicks.
#
#This script also works in the dcc console as follows:
#.remind <minutes> <text>
#
#As of this initial version, the script is NOT multi-threaded,
#which means that only one  reminder message can be stored at
#a time. If a second reminder message is stored, it will replace
#the first one.
#
#NOTES
#Accuracy is +/- 59 seconds due to the way eggdrop handles timers
#This script was designed for eggdrop1.1.5 - use it on newer
#versions at your own risk :P
#Reminders will last thru .rehash but NOT .restart
#
#INSTALLATION
#Copy this file into your eggdrop's scripts directory and add
#the following line at the end of your .conf file:
#source scripts/remind.tcl
#
#Contact dre@mac.com with any feature suggestions, or talk to dre^
#on EFnet.
#
#--------------------------------------------------------------
#Change each of the three n's below to whatever flag you want
#eggdrop to require in order for you to use remind.tcl
#set to - for no flags required

bind MSG n remind msg:remind
bind DCC n remind dcc:remind
bind NICK n * check:nick

proc msg:remind {nick uh hand text} {
	global who info
	set when [lindex $text 0]
	set info [lrange $text 1 end]
	set who $nick
	putlog "$nick set a reminder of $info for $when minutes"
	puthelp "PRIVMSG $who :Reminding you in $when minutes: $info"
	timer $when remind:msg
    }

proc dcc:remind {hand idx text} {
	global who info
	set when [lindex $text 0]
	set info [lrange $text 1 end]
	set who $idx
	putdcc $idx "Reminding you in $when minutes: $info"
	timer $when remind:dcc
    }

proc remind:msg {} {
	global who info
	puthelp "PRIVMSG $who :  $info  "
	unset who
	unset info
    }
    
proc remind:dcc {} {
	global who info
	putdcc $who "  $info  "
	unset who
	unset info
	}
	
proc check:nick {nick uh hand chan newnick} {
	global who
	if {[info exists who]} {	
		if {[string compare $who $nick] == 0} {
			putlog "Tracking reminder nick: $who --> $newnick"
			set who $newnick
			}
		}
	}
putlog "remind.tcl 1.0 by dre^ @ EFnet loaded."

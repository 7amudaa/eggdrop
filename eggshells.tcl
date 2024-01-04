##############################################################################
#  GNU
#  scheol.org
##############################################################################
#  Title      	: EggShell
#  Project    	: EggShell
##############################################################################
#  Description	: Script to enable to run linux shell commands on an IRC
#                 channel
##############################################################################
#  File       	: eggshell.tcl
#  Version		: 0.02 ß
#  Authors    	: Roshan Antony Tauro
#  Created    	: 2008/25/02
#  Modified    	: 2008/26/02
##############################################################################
#  Installation : Installation procedure is as follows:
#    			  1. Place the file into scripts directory
#    			  2. Add the following line into bots config file
#	 				 source scripts/eggshell.tcl 
#    			  3. Find the following line in eggshell.tcl
#	 			     set trigger "!" and define your own character or use ! as 
#					 default
#				  4. Rehash the bot
# Usage			: !execute <command>
##############################################################################

####### - GLOBAL CONSTANTS - #################################################

set eggshell(trigger)		"!"
set eggshell(channels)		"#dew #eggdrop"
set eggshell(ver)			"0.02"
set eggshell(allowed)		"pwd hostname ls uname tail head less" 
set eggshell(restrictlines)	5

####### - BINDINGS - ########################################################

bind pub o|o ${eggshell(trigger)}execute execute

####### - PROCEDURES - #######################################################

proc execute { nick host hand chan text } {
	global eggshell
	foreach channel $eggshell(channels) {
		if {[string match -nocase $channel $chan]} {
			set hostname [exec hostname]
			set commandfound 0;
			foreach command $eggshell(allowed) {
				if {[string match -nocase $command [lindex $text 0]]} {
					set commandfound 1;
					set fp [open "| ${text}"]
					set data [read $fp]
					if {[catch {close $fp} err]} {
						putserv "PRIVMSG ${chan} :Execution of command: ${text} failed on ${hostname}." 
					} else {
						set output [split $data "\n"]
						if {$eggshell(restrictlines) && [llength $output] > $eggshell(restrictlines)} {
							putserv "PRIVMSG ${chan} :Result of command ${text} executed on ${hostname} exceeds ${eggshell(restrictlines)} lines."
						} else {
							putserv "PRIVMSG ${chan} :Result of command ${text} executed on ${hostname}"
							foreach line $output {
								putserv "PRIVMSG ${chan} :${line}"  
							}
						}
					}
				}
			}
			if {!$commandfound} {
				putserv "PRIVMSG ${chan} :You are not allowed to run command {[lindex $text 0]} on ${hostname}"
			}
		}
	}
}

proc about {nick host hand chan text} {
	global eggshell
	putserv "PRIVMSG $nick :----------------------------------"
	putserv "PRIVMSG $nick :Script: EggShell v${eggshell(ver)}"
	putserv "PRIVMSG $nick :Author: Roshan Antony Tauro"
	putserv "PRIVMSG $nick :E-Mail: roshan@scheol.org"
	putserv "PRIVMSG $nick :----------------------------------"	
} 

proc help {nick host hand chan text} {
	global eggshell
	putserv "PRIVMSG $nick :-----------------------------------------------------"
	putserv "PRIVMSG $nick :Usage: ${eggshell(trigger)}execute <shell command(s)>"
	putserv "PRIVMSG $nick :-----------------------------------------------------"	
} 

####### - MAIN - ############################################################

set hostname [exec hostname]
putlog "EggShell tcl ${eggshell(ver)} Created by Roshan Antony Tauro"
putlog "For help type: !help on the channel"


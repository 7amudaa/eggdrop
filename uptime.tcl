# uptime.tcl v1.0 [Nov 08 2011]
# Author: Kaishiro
# Contact: kaishiro@xertion.org
# Website: http://www.xertion.org/

### Description: ###############################################################
#
# I needed an uptime script for the eggdrops hosted on each server so I can 
# get quick and real system uptime of each server without having to SSH. 
# I realize that you can see a servers uptime using simple commands on IRC, but
# I was wanting true system uptime, not link uptime. Other uptime scripts also 
# didn't allow a trigger to show privately AND publicly OR have a "server name"
# trigger. This script is a nice combination.
#
################################################################################

#### Install: ##################################################################
#
# Install by placing uptime.tcl in your /scripts directory and then add:
# "source scripts/uptime.tcl" (without quotes) to your eggdrop.conf.
# Finally .rehash or .restart your eggdrop from partyline. Enjoy.
#
################################################################################

### Commands: ##################################################################
#
# @uptime [option]
#
# Options: -p (sends the uptime in a notice)
#
################################################################################

## Config ##
set up_cmdpfix "!"

# This Option allow you to choose who can use the command. By default ops only
# can use it: "o" however you change it to "v" for voice and above, or "-" to
# allow everyone to use this command.
set userflag "o"


# Uncomment and edit this trigger for specific bot name.
# Change what is inside the parentheses.
#
# bind pub - ${up_cmdpfix}u(bot_name) pub:uptime

## Don't edit below this ##
bind pub - ${up_cmdpfix}uptime pub:uptime


proc pub:uptime {nick uhost hand chan arg} {
global up_cmdpfix userflag
	if {[matchattr $hand $userflag]} {
	if {[string first "-p" [string tolower $arg]] != -1} {
          putserv "NOTICE $nick :uptime: [up_uptime]"
         } else {
    putserv "PRIVMSG $chan :uptime: [up_uptime]"
   }
  }
 return 1
}

proc up_uptime { } {
	if {[catch {exec uptime} shelluptime] } { set shelluptime "Perl script is not executable or doesn't exist." }
	return "$shelluptime"
}

## Loaded Message ##########################################################
#
putlog "uptime.tcl v1.0 by Kaishiro loaded!"
#
############################################################################

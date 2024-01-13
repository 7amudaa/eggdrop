###############################################################################
# Bomb Squad 1.0 by rojo (EFnet #wootoff)                                     #
# Copyright 2011 Steve Church (rojo on EFnet). All rights reserved.           #
#                                                                             #
# Description:                                                                #
# timebomb script with one insta-kill wire, one disarm wire, one booby-trap   #
# wire that cuts your time remaining in half, and a random number of decoys.  #
#                                                                             #
# Please report bugs to rojo on EFnet.                                        #
#                                                                             #
# License                                                                     #
#                                                                             #
# Redistribution and use in source and binary forms, with or without          #
# modification, are permitted provided that the following conditions are met: #
#                                                                             #
#   1. Redistributions of source code must retain the above copyright notice, #
#      this list of conditions and the following disclaimer.                  #
#                                                                             #
#   2. Redistributions in binary form must reproduce the above copyright      #
#      notice, this list of conditions and the following disclaimer in the    #
#      documentation and/or other materials provided with the distribution.   #
#                                                                             #
# THIS SOFTWARE IS PROVIDED BY STEVE CHURCH "AS IS" AND ANY EXPRESS OR        #
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES   #
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN  #
# NO EVENT SHALL STEVE CHURCH OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,       #
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES          #
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR          #
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER  #
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT          #
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY   #
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH #
# DAMAGE.                                                                     #
###############################################################################

namespace eval bombsquad {

set settings(udef-flag) timebomb        ;# .chanset #channel +timebomb
set settings(ignore-flags) bkqr|kqr     ;# ignore requests by users with these flags
set settings(protect-owner) 1           ;# protect bot owner from being bombed
set settings(god-mode) mn               ;# users with these flags can timebomb anyone
set settings(idle-mins-assume-away) 5   ;# users idle this many minutes will be considered away
set settings(cheat) 0                   ;# putlog the answer so you know which wire to cut
set settings(triggers) {
	!bomb
	!timebomb
}
set settings(wires) {
	red
	yellow
	green
	blue
	white
	orange
	black
	brown
	gray
}
set settings(locations) {
	pants
	nose
	nostril
	vagina
	ear
	mouth
	{butt crack}
	shoe
	bra
	{pee hole}
	anus
	rectum
	sock
	{chest cavity}
	{eye socket}
	{belly button}
	urethra
	pecker
	vajayjay
	{pee pee}
	woody
}
set settings(methods) {
	stuffs
	crams
	sticks
	shoves
	hides
	rams
	crams
	leaves
	puts
	plants
}

array set current [list]
variable current
variable settings
variable ns [namespace current]

setudef flag $settings(udef-flag)

foreach t $settings(triggers) {
	bind pub * $t ${ns}::get_target
}
foreach c $settings(wires) {
	bind pubm * *$c ${ns}::cut_wire
}

# round(nick) = target
# round(uhost) = target uhost
# round(wires) = list of all wires in play
# round(trigger) = makes bomb asplode
# round(timer) = defuses the bomb
# round(trap) = halves the time left

proc list2pretty {what} {
	if {[llength $what] == 1} { return [lindex $what 0] }
	set last [lindex $what end]
	set first [join [lreplace $what end end] "\002, \002"]
	return "\002$first\002 or \002$last\002"
}

proc get_target {nick uhost hand chan txt} {
	variable current; variable settings; variable ns
	global botnick
	if {[matchattr $hand $settings(ignore-flags)] || ![channel get $chan $settings(udef-flag)]} { return }
	if {[info exists current($chan)]} {
		array set round $current($chan)
		puthelp "PRIVMSG $chan :\001ACTION turns $nick's attention to $round(nick)'s $round(location) and winks.\001"
		return
	}
	set txt [string trim $txt]
	if {![string length $txt] || ![onchan $txt $chan]} {
		set target $nick
	} elseif {[matchattr $hand $settings(god-mode)]} {
		set target $txt
	} elseif {[matchattr [nick2hand $txt] b] || [string equal -nocase $txt $botnick]} {
		set target $nick
	} elseif {$settings(protect-owner) && [matchattr [nick2hand $txt] n]} {
		set target $nick
	} else {
		set target $txt
	}
	foreach v {nick uhost hand chan target} { set settings(tmp$v) [set $v] }
	bind raw - 301 ${ns}::user_is_away
	bind raw - 318 ${ns}::set_bomb
	if {[matchattr $hand $settings(god-mode)] || [string equal -nocase $nick $target]} {
		set_bomb
	} elseif {[set idle [getchanidle $target $chan]] >= $settings(idle-mins-assume-away)\
	&& $nick != $target} {
		user_is_idle $idle
	} else {
		dump "WHOIS $target"
	}
}

proc user_is_idle {idle} {
	variable settings; variable ns
	puthelp "PRIVMSG $settings(tmpchan) :$settings(tmpnick): $settings(tmptarget) has been\
	idle for $idle minutes, and probably isn't even paying attention.  You're an asshole."
	foreach v {nick uhost hand chan target} { unset settings(tmp$v) }
	unbind raw * 301 ${ns}::user_is_away
	unbind raw * 318 ${ns}::set_bomb
}

proc user_is_away {args} {
	variable settings; variable ns
	puthelp "PRIVMSG $settings(tmpchan) :$settings(tmpnick): $settings(tmptarget) is /AWAY. \
	You're an asshole."
	foreach v {nick uhost hand chan target} { unset settings(tmp$v) }
	unbind raw * 301 ${ns}::user_is_away
	unbind raw * 318 ${ns}::set_bomb
}

proc set_bomb {args} {
	variable current; variable settings; variable ns
	unbind raw * 301 ${ns}::user_is_away
	unbind raw * 318 ${ns}::set_bomb
	if {![info exists settings(tmptarget)]} { return }
	foreach v {nick uhost hand chan target} { set $v $settings(tmp$v); unset settings(tmp$v) }
	set round(nick) $target
	set round(uhost) [getchanhost $target]
	set round(wires) [list]
	set wires $settings(wires)
	set p [expr {[llength $wires] - 4}]
	set lim [expr {[rand $p] + 4}]
	for {set i 0} {$i < $lim} {incr i} {
		set idx [rand [llength $wires]]
		lappend round(wires) [lindex $wires $idx]
		set wires [lreplace $wires $idx $idx]
	}
	set wires $round(wires)
	foreach item {trigger timer trap} {
		set idx [rand [llength $wires]]
		set round($item) [lindex $wires $idx]
		set wires [lreplace $wires $idx $idx]
	}
	set does_something_with [lindex $settings(methods) [rand [llength $settings(methods)]]]
	set foul_place [lindex $settings(locations) [rand [llength $settings(locations)]]]
	set round(location) $foul_place
	set more_or_less [expr {[rand 10] - 5}]
	set time [expr {[llength $round(wires)] * 8 + $more_or_less}]
	putquick "PRIVMSG $chan :\001ACTION $does_something_with a bomb in $target's $foul_place.\001"
	if {$settings(cheat)} {
		putlog "\00304trigger: $round(trigger)\003;  \00303timer: $round(timer)\003;  \00307trap: $round(trap)\003"
	}
	utimer $time [list ${ns}::asplode $chan]
	set current($chan) [array get round]
	status $chan
}

proc status {chan} {
	variable ns; variable current
	foreach t [utimers] {
		if {[string equal [lindex $t 1] [list ${ns}::asplode $chan]]} {
			array set round $current($chan)
			putquick "PRIVMSG $chan :The timer reads [lindex $t 0] seconds.  Cut one of the following wires: [list2pretty $round(wires)]"
			break
		}
	}
}

proc stop_timers {chan} {
	variable ns
	foreach t [utimers] {
		if {[string equal [lindex $t 1] [list ${ns}::asplode $chan]]} {
			set left [lindex $t 0]
			killutimer [lindex $t 2]
			return $left
		}
	}
}

proc cut_wire {nick uhost hand chan txt} {
	variable ns; variable current
	if {![info exists current($chan)]} { return }
	array set round $current($chan)
	if {![string equal $uhost $round(uhost)]} { return }
	if {[set match [lsearch -nocase $round(wires) $txt]] == -1} { return }
	set txt [lindex $round(wires) $match]
	if {[string equal $txt $round(trigger)]} {
		stop_timers $chan
		asplode $chan
	} elseif {[string equal $txt $round(trap)]} {
		set idx [lsearch -nocase $round(wires) $round(trap)]
		set round(wires) [lreplace $round(wires) $idx $idx]
		set current($chan) [array get round]
		set left [expr {[stop_timers $chan] / 2}]
		utimer $left [list ${ns}::asplode $chan]
		putquick "PRIVMSG $chan :$nick: Oh, shit!  You tripped a booby trap!  The timer just doubled in speed!"
		status $chan
	} elseif {[string equal $txt $round(timer)]} {
		set left [stop_timers $chan]
		if {$left == 1} { set left "one second" } { set left "$left seconds" }
		puthelp "PRIVMSG $chan :$nick: Great job!  You defused the bomb with $left on the timer."
		unset current($chan)
	} else {
		set idx [lsearch -nocase $round(wires) $txt]
		set round(wires) [lreplace $round(wires) $idx $idx]
		set current($chan) [array get round]
		putquick "PRIVMSG $chan :$nick: The $txt wire was a decoy.  The clock is still ticking.  Try again."
		status $chan
	}
}

proc asplode {chan} {
	variable ns; variable current
	array set round $current($chan)
	unset current($chan)
	if {[onchan $round(nick)]} {
		set target $round(nick)
	} else {
		foreach nick [chanlist $chan] {
			if {[string equal [getchanhost $nick] $round(uhost)]} {
				set target $nick
				break
			}
		}
	}
	if {[info exists target]} {
		if {[botisop $chan]} {
			putkick $chan $target "BOOOOO000oooooOOOOOoooo0000OOOOOMMMM!!!!!1"
		} else {
			puthelp "PRIVMSG $chan :BOOOOO000oooooOOOOOoooo0000OOOOOMMMM!!!!!1  $target is dead."
		}
	} else {
		puthelp "PRIVMSG $chan :$round(nick) was a pussy."
	}
}

putlog "bombsquad.tcl loaded."

}; # end namespace

# # Usage:
#	?blackjack 			- Start a game
#	?blackjack on 		- Turn on Blackjack in the Channel
#	?blackjack off		- Turn off Blackjack in the Channel
#	?blackjack stats	- Get Channel statistics for Blackjack
#	?blackjack version	- Shows the Blackjack script version
#	?join 				- Join a game
#	?card 				- Get a card
#	?enough				- Finish
#	?stop				- Just for Bot Owners, stop a game if it freezes by a bug
#
#
#
# # Copyright
#
# Copyright (C) 2006  Michael 'bloodLiner' Gecht
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#
# # Configuration:
#
# Game trigger, strandard is ?blackjack
set ::blackjack(trigger) "\?"

# Floodtime, 300 seconds = 5 minutes
set ::blackjack(flood) "300"

#
# # DON'T CHANGE ANYTHING BEYOND THIS LINE, UNTIL YOU KNOW WHAT YOU ARE DOING!

set bj(author) 		"lilmoe"
set bj(web) 		"http://www.lilmoe.scripts"
set bj(name) 		"Blackjack Script"
set bj(version) 	"v6.0"

setudef 	flag 	blackjack
setudef 	str  	blackjackc

bind pub 	* 	$::blackjack(trigger)blackjack 	game:blackjack
bind pub 	* 	$::blackjack(trigger)join 		blackjack:join
bind pub 	* 	$::blackjack(trigger)card 		blackjack:karte
bind pub 	* 	$::blackjack(trigger)enough	 	blackjack:genug
bind pub 	n 	$::blackjack(trigger)stop 		blackjack:stop

# sendmsg proc by ircscript.de - R.I.P. #dew
proc sendmsg {target command message} {
	if {![string match "#*" $target]} {
		putquick "notice $target :\002  $command    \002 $message \002 \002"
	} else {
		if {[string match "*c*" [getchanmode $target]]} {
			putquick "privmsg $target :  $command     $message  "
		} else {
			putquick "privmsg $target :\002  $command    \002 $message \002 \002"
		}
	}
}

# string2pattern proc by CyBex - tclhelp.net
proc str2pat {string} {
	return [string map [list \\ \\\\ \[ \\\[ \] \\\] ] $string]
}

proc game:blackjack {nick host hand chan arg} {
	switch -exact -- [string tolower [lindex [split $arg] 0]] {
		"on" {
			if {![matchattr $hand n|n $chan]} {
				return 0
			}
			if {[channel get $chan "blackjack"]} {
				putserv "notice $nick :The game Blackjack is already enabled on $chan."
				return 0
			} elseif {![channel get $chan "blackjack"]} {
				channel set $chan +blackjack
				putserv "notice $nick :The game Blackjack was successfully enabled on $chan."
			}
		}
		"off" {
			if {![matchattr $hand n|n $chan]} {
				return 0
			}
			if {![channel get $chan "blackjack"]} {
				putserv "notice $nick :The game Blackjack is already disabled on $chan."
				return 0
			} elseif {[channel get $chan "blackjack"]} {
				channel set $chan -blackjack
				putserv "notice $nick :The game Blackjack was successfully disabled on $chan."
			}
		}
		"stats" {
			if {[info exists ::blackjack(flood,count,$chan)] && [expr {[unixtime] - $::blackjack(flood,count,$chan)}] < 300} {
			} else {
				if {[channel get $chan "blackjackc"] == ""} {
					sendmsg $chan Blackjack "I have never seen any game on $chan!"
				} elseif {[channel get $chan "blackjackc"] == "1"} {
					sendmsg $chan Blackjack "I have seen exactly one game on $chan!"
				} else {
					sendmsg $chan Blackjack "I have seen [channel get $chan "blackjackc"] games on $chan!"
				}
				set ::blackjack(flood,count,$chan) [unixtime]
				utimer 300 [list unset ::blackjack(flood,count,$chan)]
			}
		}
		"version" {
			global bj
			if {[info exists ::blackjack(flood,version,$chan)] && [expr {[unixtime] - $::blackjack(flood,version,$chan)}] < 300} {
			return 0
			} else {
				sendmsg $chan Blackjack "I'm using the $bj(name) $bj(version) by $bj(author) - $bj(web)"
				set ::blackjack(flood,version,$chan) [unixtime]
				utimer 300 [list unset ::blackjack(flood,version,$chan)]
			}
		}
		"" {
			if {![channel get $chan "blackjack"]} {
				return 0
			} elseif {[info exists ::blackjack(flood,$chan)] && [expr {[unixtime] - $::blackjack(flood,$chan)}] < $::blackjack(flood)} {
				return 0
			} else {
				if {[info exists ::blackjack(request,$chan)] == "1" || [info exists ::blackjack(started,$chan)] == "1"} {
					puthelp "notice $nick :There is already a Blackjack game running on $chan"
					return 0
				} else {
					set ::blackjack(request,$chan) "1"
				}
			}
			if {$::blackjack(request,$chan) == "1"} {
				set ::blackjack(player,$chan) "[str2pat $nick]"
				set ::blackjack(active,$chan) "0"
				sendmsg $chan Blackjack "The game will start in the next 30 seconds! Type $::blackjack(trigger)join to join the game!"
				utimer 30 [list blackjack:expire $chan]
				return
			}
		}
	}
}

proc blackjack:join {nick host hand chan arg} {
	if {![channel get $chan "blackjack"]} {
		return 0
	} elseif {[info exists ::blackjack(request,$chan)] == "0"} {
		return 0
	} elseif {[llength $::blackjack(player,$chan)] == 5} {
		puthelp "notice $nick :The Blackjack game is already full!"
		return 0
	}
	if {[lsearch $::blackjack(player,$chan) [str2pat $nick]] == "-1"} {
		lappend ::blackjack(player,$chan) $nick
		puthelp "notice $nick :You successfully joined the Blackjack game on $chan."
	} else {
		puthelp "notice $nick :You already joined the Blackjack game on $chan"
	}
}

proc blackjack:expire {chan} {
	if {[llength $::blackjack(player,$chan)] < 2} {
		sendmsg $chan Blackjack "The 30 seconds are over and no one wants to play!"
		unset ::blackjack(player,$chan)
		unset ::blackjack(request,$chan)
	} else {
		unset ::blackjack(request,$chan)
		set ::blackjack(started,$chan) "1"
		foreach player $::blackjack(player,$chan) {
			set ::blackjack(gesamt,wert,$chan,[getchanhost $player]) "0"
			set ::blackjack(gesamt,karten,$chan,[getchanhost $player]) ""
		}
		set ::blackjack(stapel,Club,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
		set ::blackjack(stapel,Spade,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
		set ::blackjack(stapel,Heart,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
		set ::blackjack(stapel,Diamonds,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
		set ::blackjack(stapel,alle,$chan) "Club Spade Heart Diamonds"
		sendmsg $chan Blackjack "Let the game begin! The players are [join $::blackjack(player,$chan) ", "]. Get a card with $::blackjack(trigger)card. If you have enough type $::blackjack(trigger)enough. [lindex $::blackjack(player,$chan) 0] begins!"
		set ::blackjack(idletimer,$chan) [utimer 60 [list blackjack:idle [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)] $chan]]
	}
}

proc blackjack:karte {nick host hand chan arg} {
	if {![channel get $chan "blackjack"]} {
		return 0
	} elseif {![info exists ::blackjack(started,$chan)]} {
		return 0
	} elseif {$nick != [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)]} {
		return 0
	}

	if {[info exists ::blackjack(idletimer,$chan)]} {
		killutimer $::blackjack(idletimer,$chan)
		unset ::blackjack(idletimer,$chan)
	}

	foreach stapel $::blackjack(stapel,alle,$chan) {
		if {[llength $::blackjack(stapel,$stapel,$chan)] < 1} {
			set ::blackjack(stapel,alle,$chan) "[lrange $::blackjack(stapel,alle,$chan) 0 [expr {[lsearch -exact $::blackjack(stapel,alle,$chan) $stapel] - 1}]] [lrange $::blackjack(stapel,alle,$chan) [expr {[lsearch -exact $::blackjack(stapel,alle,$chan) $stapel] + 1}] end]"
			set ::blackjack(stapel,$chan) "[rand [llength $::blackjack(stapel,alle,$chan)]]"
			set ::blackjack(stapelw,$chan) "[lindex $::blackjack(stapel,alle,$chan) $::blackjack(stapel,$chan)]"
			set ::blackjack(karte,$chan) "[rand [llength $::blackjack(stapel,$::blackjack(stapelw,$chan),$chan)]]"
			set ::blackjack(wert,$chan) "[lindex $::blackjack(stapel,[lindex $::blackjack(stapel,alle,$chan) $::blackjack(stapel,$chan)],$chan) $::blackjack(karte,$chan)]"
		} else {
			set ::blackjack(stapel,$chan) "[rand [llength $::blackjack(stapel,alle,$chan)]]"
			set ::blackjack(stapelw,$chan) "[lindex $::blackjack(stapel,alle,$chan) $::blackjack(stapel,$chan)]"
			set ::blackjack(karte,$chan) "[rand [llength $::blackjack(stapel,$::blackjack(stapelw,$chan),$chan)]]"
			set ::blackjack(wert,$chan) "[lindex $::blackjack(stapel,[lindex $::blackjack(stapel,alle,$chan) $::blackjack(stapel,$chan)],$chan) $::blackjack(karte,$chan)]"
		}
	}
	if {$::blackjack(stapelw,$chan) == "Club" || $::blackjack(stapelw,$chan) == "Spade"} {
		set blackjack(farbe,$chan) "\0031,0"
	} elseif {$::blackjack(stapelw,$chan) == "Heart" || $::blackjack(stapelw,$chan) == "Diamonds"} {
		set blackjack(farbe,$chan) "\0030,2"
	}

	if {$::blackjack(gesamt,wert,$chan,$host) == 21 || $::blackjack(gesamt,wert,$chan,$host) > 21} {
		puthelp "notice $nick :Your value is already $::blackjack(gesamt,wert,$chan,$host)! Now type $::blackjack(trigger)enough."
		return 0
	} elseif {$::blackjack(wert,$chan) == "Jack" || $::blackjack(wert,$chan) == "Queen" ||  $::blackjack(wert,$chan) == "King"} {
		set ::blackjack(gesamt,wert,$chan,$host) "[expr {$::blackjack(gesamt,wert,$chan,$host) + 10}]"
	} elseif {$::blackjack(wert,$chan) == "Ace"} {
		if {[expr {$::blackjack(gesamt,wert,$chan,$host) + 11}] > 21} {
			set ::blackjack(gesamt,wert,$chan,$host) "[expr {$::blackjack(gesamt,wert,$chan,$host) + 1}]"
		} else {
			set ::blackjack(gesamt,wert,$chan,$host) "[expr {$::blackjack(gesamt,wert,$chan,$host) + 11}]"
		}
	} else {
		set ::blackjack(gesamt,wert,$chan,$host) "[expr {$::blackjack(gesamt,wert,$chan,$host) + $::blackjack(wert,$chan)}]"
	}

	set ::blackjack(gesamt,karten,$chan,$host) " $::blackjack(gesamt,karten,$chan,$host) $blackjack(farbe,$chan)$::blackjack(stapelw,$chan) $::blackjack(wert,$chan)\003"

	putquick "notice $nick :Your Cards:$::blackjack(gesamt,karten,$chan,$host) - Total Value: $::blackjack(gesamt,wert,$chan,$host)"
	set ::blackjack(stapel,[lindex $::blackjack(stapel,alle,$chan) $::blackjack(stapel,$chan)],$chan) "[lrange $::blackjack(stapel,[lindex $::blackjack(stapel,alle,$chan) $::blackjack(stapel,$chan)],$chan) 0 [expr {$::blackjack(karte,$chan)-1}]] [lrange $::blackjack(stapel,[lindex $::blackjack(stapel,alle,$chan) $::blackjack(stapel,$chan)],$chan) [expr {$::blackjack(karte,$chan)+1}] end]"
}

proc blackjack:idle {nick chan} {
	sendmsg $chan Blackjack "$nick seems to be sleeping... What the hell am i doing here!?"
	unset ::blackjack(idletimer,$chan)
	blackjack:genug $nick [getchanhost $nick] [nick2hand $nick] $chan keyed
}

proc blackjack:kick {nick chan} {
	set ::player(kick,$chan) "$::blackjack(player,$chan)"
	set ::blackjack(player,$chan) ""
	foreach players $::player(kick,$chan) {
		if {$players != $nick} {
			lappend ::blackjack(player,$chan) "$players"
		} else {
			continue;
		}
	}
	unset ::player(kick,$chan)
}

proc blackjack:genug {nick host hand chan arg} {
	if {![channel get $chan "blackjack"]} {
		return 0
	} elseif {![info exists ::blackjack(started,$chan)]} {
		return 0
	}
	if {$nick != [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)]} {
		return 0
	}
	if {$::blackjack(gesamt,wert,$chan,$host) == 0 && [llength $::blackjack(gesamt,karten,$chan,$host)] == 0 && $arg != "keyed"} {
		puthelp "notice $nick :You have to receive at least one card, before you can use $::blackjack(trigger)enough"
		return 0
	} elseif {$::blackjack(gesamt,wert,$chan,[getchanhost [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)]]) > 21 || $::blackjack(gesamt,wert,$chan,[getchanhost [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)]]) == "0" && $arg == "keyed"} {
		blackjack:kick [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)] $chan
	} else {
		incr ::blackjack(active,$chan)
	}
	if {[expr {[llength $::blackjack(player,$chan)]-1}] < $::blackjack(active,$chan)} {
		if {[llength $::blackjack(player,$chan)] < 1} {
			sendmsg $chan Blackjack "Draw! All players dropped out!"
		} else {
			set ::blackjack(winner,$chan,check) "$::blackjack(gesamt,wert,$chan,[getchanhost [lindex $::blackjack(player,$chan) 0]])"
			set ::blackjack(winner,$chan) "[lindex $::blackjack(player,$chan) 0]"
			set ::blackjack(winner,$chan,zahl) "1"
			foreach player $::blackjack(player,$chan) {
				if {$::blackjack(winner,$chan) == $player} {
					continue;
				} elseif {$::blackjack(gesamt,wert,$chan,[getchanhost $player]) > 21} {
					continue;
				} elseif {$::blackjack(gesamt,wert,$chan,[getchanhost $player]) > $::blackjack(winner,$chan,check)} {
					set ::blackjack(winner,$chan) "$player"
					set ::blackjack(winner,$chan,check) "$::blackjack(gesamt,wert,$chan,[getchanhost $player])"
					continue;
				} elseif {$::blackjack(gesamt,wert,$chan,[getchanhost $player]) == $::blackjack(winner,$chan,check)} {
					lappend ::blackjack(winner,$chan) "$player"
					continue;
				}
			}
			if {[llength $::blackjack(winner,$chan)] > 1} {
				set ::blackjack(player,$chan) "$::blackjack(winner,$chan)"
				foreach player $::blackjack(player,$chan) {
					set ::blackjack(gesamt,wert,$chan,[getchanhost $player $chan]) "0"
					set ::blackjack(gesamt,karten,$chan,[getchanhost $player $chan]) ""
				}
				set ::blackjack(stapel,Club,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
				set ::blackjack(stapel,Spade,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
				set ::blackjack(stapel,Heart,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
				set ::blackjack(stapel,Diamonds,$chan) "Ace 2 3 4 5 6 7 8 9 10 Jack Queen King"
				set ::blackjack(stapel,alle,$chan) "Club Spade Heart Diamonds"
				set ::blackjack(active,$chan) "0"
				sendmsg $chan Blackjack "The players [join $::blackjack(player,$chan) ", "] have the same value: $::blackjack(winner,$chan,check). That's why a new round is going to begin! [lindex $::blackjack(player,$chan) 0] begins."
				set ::blackjack(idletimer,$chan) [utimer 60 [list blackjack:idle [lindex $::blackjack(player,$chan) 0] $chan]]
				return 0
			} else {
				sendmsg $chan Blackjack "The winner is $::blackjack(winner,$chan) with the value of $::blackjack(gesamt,wert,$chan,[getchanhost $::blackjack(winner,$chan) $chan])!"
			}
			unset ::blackjack(winner,$chan)
			unset ::blackjack(winner,$chan,zahl)
			unset ::blackjack(winner,$chan,check)
		}
		if {[channel get $chan "blackjackc"] == ""} {
			set bjcount "0"
		} else {
		set bjcount "[channel get $chan blackjackc]"
		}
		incr bjcount
		channel set $chan blackjackc "$bjcount"
		set ::blackjack(flood,$chan) [unixtime]
		utimer 300 [list unset ::blackjack(flood,$chan)]
		foreach player $::blackjack(player,$chan) {
			unset ::blackjack(gesamt,wert,$chan,[getchanhost $player $chan])
		}
		unset ::blackjack(player,$chan)
		unset ::blackjack(started,$chan)
		unset ::blackjack(stapel,Club,$chan)
		unset ::blackjack(stapel,Spade,$chan)
		unset ::blackjack(stapel,Heart,$chan)
		unset ::blackjack(stapel,Diamonds,$chan)
		unset ::blackjack(stapel,alle,$chan)
		unset ::blackjack(stapel,$chan)
		unset ::blackjack(stapelw,$chan)
		unset ::blackjack(karte,$chan)
		unset ::blackjack(wert,$chan)
		return 0
	} else {
		sendmsg $chan Blackjack "Ok, [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)] you're next!"
		set ::blackjack(idletimer,$chan) [utimer 60 [list blackjack:idle [lindex $::blackjack(player,$chan) $::blackjack(active,$chan)] $chan]]
	}
}

proc blackjack:stop {nick host hand chan arg} {
	if {[info exists ::blackjack(request,$chan)]} {
		unset ::blackjack(request,$chan)
		putquick "notice $nick :Done! The variable \$::blackjack(request,$chan) has been reseted on $chan!"
	}
	if {[info exists ::blackjack(started,$chan)]} {
		unset ::blackjack(started,$chan)
		putquick "notice $nick :Done! The variable \$::blackjack(started,$chan) has been reseted on $chan!"
	}
}

putlog "Loaded $bj(name) $bj(version) by $bj(author) - $bj(web)"

# EOF

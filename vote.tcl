# CV Script (Channel Voter Script)
# Written by Loki` (#FTP4Warez on EFNet)
#
#Type '/msg <botnick> vote help' for commands

#Version History:
#
#10/02/2001 - 1.0	Initial Release
#10/05/2001 - 1.1b	Added support for rehashing without losing current vote
#10/21/2001 - 1.1	Added !endvote and !time chan commands
#11/16/2001 - 1.12	Added Tie Breaking support (extends time)
#			Added support for voter selection (S, o, v or -) 
#			(- means anyone, S for senior vote (user must have +S flag))
#			Commands added:
#				!seniorvote
#				!opvote (default)
#				!voicevote
#				!anyvote
#			Disallowed voting using a bot (Thanks, redstar, for the ..uhm 'hint')
#11/24/2001 - 1.13	Added hostmasking to identify voters (No more dialup user vote reminders)
#12/11/2001 - 1.14	Fixed the "Time Left" counter.  It was displaying the full time throughout the vote
#			Fixed the hostmasking support (was causing ppl to not be able to vote, heh)
#12/20/2001 - 1.15	Fixed a bug where the bot msg'd people to vote who already voted

###------------------------ Vote Bindings ------------------------###
bind pub o|o "!startvote" vote_start
bind pub o|o "!endvote" vote_results
bind pub o|o "!seniorvote" senior_vote
bind pub o|o "!opvote" op_vote
bind pub o|o "!voicevote" voice_vote
bind pub o|o "!anyvote" any_vote
bind pub o|o "!vote" vote_update
bind pub o|o "!time" vote_timer
bind msg o|o vote vote_vote
bind join o|o * vote_reminder


###------------------------ Detect and remove old voting data on startup ------------------------###
if {![info exists voting]} {
	set voting no
	set voting_chan none
	catch {
		killutimer $voteset(t1)
		killutimer $voteset(t2)
		killutimer $voteset(t3)
		killutimer $voteset(t4)
		killutimer $voteset(t5)
	}
}

###------------------------ Start the vote ------------------------###
proc vote_start {nick mask hand chan text} {
	global voting voting_chan botnick vote_topic vote_no vote_yes voted_people vote_time vote_timestart vote_comments voteset
		if {$voting == "yes"} {
			putserv "NOTICE $nick :\002\|\00312Vote\003\|\002 Only one voting session allowed at once.  Please wait until this session has completed."
			return 0
		} else {
		set timeleft [lindex $text 0]
		if [string match "*m" [string tolower [lindex $text 0]]] {
			set vote_time [expr [string trimright $timeleft m] * 60]
			set vote_timestart [unixtime]
		} elseif [string match "*h" [string tolower [lindex $text 0]]] {
			set vote_time [expr [string trimright $timeleft h] * 3600]
			set vote_timestart [unixtime]
		} else {
			puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 Please type '\0034/msg $botnick vote help\003' for help."
			return 0
		}
		set voting yes
		set voting_chan $chan
		if [info exists vote_comments] {
			unset vote_comments
		}
		set vote_yes 0
		set vote_no 0
                set vote_topic [lrange $text 1 end]
		putlog "\0033 $nick $chan started voting on $vote_topic"
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002 Now voting on:\002 $vote_topic\002"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 Please place your votes!  '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002  \002[duration $vote_time]\002 left!"
		set vote_timer4th [expr $vote_time / 4]
		if {$vote_time > 1200} {
			set voteset(t1) [utimer [expr $vote_timer4th + $vote_timer4th+ $vote_timer4th] vote_warning]
		}
		if {$vote_time > 2400} {
			set voteset(t2) [utimer $vote_timer4th vote_warning]
			set voteset(t3) [utimer [expr $vote_timer4th + $vote_timer4th] vote_warning]
			set voteset(t4) [utimer [expr $vote_time - 360] vote_warning]
		}
			set voteset(t5) [utimer $vote_time "vote_results 1 2 3 4 5"]
		if {[info exists voted_people]} { unset voted_people }
		return 1
		}
}

###------------------------ Process vote triggers (yes/no/comment) ------------------------###
proc vote_vote {nick mask hand text} {
global vote_yes vote_no voted_people voting vote_comments botnick voting_chan
	if {[string tolower [lindex $text 0]] == "help"} {
		vote_helplist $nick
		return 0
	}
	set mask [maskhost $mask]
	if {$voting == "no"} {
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 There are no votes open now"
		return 0
	} elseif [matchattr $hand b] {
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 Whoever's controlling this bot, nice try!"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 Someone's trying to vote using $nick!"
		return 0
	} elseif {[string tolower [lindex $text 0]] == "comments"} {
		vote_commentlist $nick
		return 0
	} elseif {[string tolower [lindex $text 0]] == "stats"} {
		vote_statlist $nick
		return 0
	} elseif {[info exists voted_people($mask)]} {
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 Sorry, you already voted"
		return 0
	} elseif {[string tolower [lindex $text 0]] == "yes"} {
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 Your vote has been counted!"
		set vote_yes [incr vote_yes]
	        if {[lrange $text 1 end] != ""} {
		        set vote_comments($nick) [lrange $text 1 end]
		}
		set voted_people($mask) 1
		return 0
	} elseif {[string tolower [lindex $text 0]] == "no"} {
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 Your vote has been counted!"
		set vote_no [incr vote_no]
	        if {[lrange $text 1 end] != ""} {
		        set vote_comments($nick) [lrange $text 1 end]
		}
		set voted_people($mask) 1
		return 0
	} else {
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 Please type '\0034/msg $botnick vote help\003' for help."
	}
}

###------------------------ Seniorvote Trigger ------------------------###
proc senior_vote {nick mask hand chan text} {
global voting_chan vote_yes vote_no vote_topic voting botnick
	vote_unbind
	bind pub S|S "!vote" vote_update
	bind pub S|S "!time" vote_timer
	bind msg S|S vote vote_vote
	bind join S|S * vote_reminder
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 \002Voting now open for group seniors ONLY!!\002"
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
}

###------------------------ Opvote Trigger ------------------------###
proc op_vote {nick mask hand chan text} {
global voting_chan vote_yes vote_no vote_topic voting botnick
	vote_unbind
	bind pub o|o "!vote" vote_update
	bind pub o|o "!time" vote_timer
	bind msg o|o vote vote_vote
	bind join o|o * vote_reminder
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 \002Voting now open for ops only!! \(Make up your mind, already!\)\002"
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
}

###------------------------ Voicevote Trigger ------------------------###
proc voice_vote {nick mask hand chan text} {
global voting_chan vote_yes vote_no vote_topic voting botnick
	vote_unbind
	bind pub vo|vo "!vote" vote_update
	bind pub vo|vo "!time" vote_timer
	bind msg vo|vo vote vote_vote
	bind join vo|vo * vote_reminder
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 \002Voting now open for all +v people!!\002"
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
}

###------------------------ Anyvote Trigger ------------------------###
proc any_vote {nick mask hand chan text} {
global voting_chan vote_yes vote_no vote_topic voting botnick
	vote_unbind
	bind pub - "!vote" vote_update
	bind pub - "!time" vote_timer
	bind msg - vote vote_vote
	bind join - * vote_reminder
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 \002Voting now open for anyone!!\002"
	puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
}

###------------------------ Mass Unbind ------------------------###
proc vote_unbind {} {
	catch {
		unbind pub S|S "!vote" vote_update
		unbind pub S|S "!time" vote_timer
		unbind msg S|S vote vote_vote
		unbind join S|S * vote_reminder
		unbind pub o|o "!vote" vote_update
		unbind pub o|o "!time" vote_timer
		unbind msg o|o vote vote_vote
		unbind join o|o * vote_reminder
		unbind pub v|v "!vote" vote_update
		unbind pub v|v "!time" vote_timer
		unbind msg v|v vote vote_vote
		unbind join v|v * vote_reminder
		unbind pub - "!vote" vote_update
		unbind pub - "!time" vote_timer
		unbind msg - vote vote_vote
		unbind join - * vote_reminder
	}
	return
}

###------------------------ Display Results ------------------------###
proc vote_results {nick mask hand chan text} {
global voting_chan vote_yes vote_no vote_topic voting voteset
	if {$voting == "yes"} {
		if {$vote_yes == $vote_no && $nick == 1} {
			tie_breaker
			putlog "\0033 Vote has resulted in a tie: extending time"
			return 0
		}
		set voting no
		catch {
			killutimer $voteset(t1)
			killutimer $voteset(t2)
			killutimer $voteset(t3)
			killutimer $voteset(t4)
			killutimer $voteset(t5)
		}
		putlog "\0033 vote finished: $vote_topic Yes: $vote_yes  No: $vote_no"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 Voting results for: \002$vote_topic\002"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 Yes: \002$vote_yes\002"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 No: \002$vote_no\002"
	}
}

###------------------------ Display Current/Last Vote ------------------------###
proc vote_update {nick mask hand chan text} {
global voting_chan vote_yes vote_no vote_topic voting voteset vote_timestart vote_time
	if {[string match "yes" $voting] == 1 && [string match $chan $voting_chan] == 1} {
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002 Voting in session for: \002$vote_topic\002"
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002 Yes: \002$vote_yes\002"
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002 No: \002$vote_no\002"
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002  \0034 [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]]\003 left to vote"
	} elseif {[string match "no" $voting] == 1 && [info exists vote_topic] == 1} {
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002 Last vote was for: $vote_topic"
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002 Final tally was: Yes: \0034 $vote_yes\003 | No: \0034 $vote_no\003"
	} else {
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002 No prior votes recorded for this channel"
	}
}

###------------------------ Voting Stats ------------------------###
proc vote_statlist {nick} {
global voting_chan vote_yes vote_no vote_topic voting botnick
puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Current Voting Stats for: \002$vote_topic\002"
puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Yes: \002$vote_yes\002"
puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 No: \002$vote_no\002"
puthelp "PRIVMSG $nick :Type '\00312/msg $botnick vote comments\003' to view current voter comments"
}

###------------------------ Voting Comments ------------------------###
proc vote_commentlist {nick} {
global voting_chan vote_yes vote_no vote_topic voting vote_comments
if {![info exists vote_comments]} {
	puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 No comments made."
	return 0
}
foreach comment [array names vote_comments] {
	puthelp "PRIVMSG $nick :\002\|\00312 $comment \003\|\002 $vote_comments($comment)"
}
}

###------------------------ Voting Stats ------------------------###
proc vote_helplist {nick} {
global voting_chan vote_yes vote_no vote_topic voting botnick
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 \002Voting Commands \(For during a voting session\)\002:"
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034/msg $botnick vote yes \[comment\]\003' for a 'yes' vote."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034/msg $botnick vote no \[comment\]\003' for a 'no' vote."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034/msg $botnick vote stats\003' for current tallied votes."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034/msg $botnick vote comments\003' to view current comments."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!endvote\003' to end a voting session early."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!vote\003' to display current vote in session."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!time\003' to display voting time remaining."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!seniorvote\003' to limit voting to seniors only (+S users on bot)."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!opvote\003' to limit voting to ops only (Default)."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!voicevote\003' to limit voting to voice users (+v or above on bot)."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!anyvote\003' to allow anyone to vote."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 \002Voting Commands \(For outside a voting session\)\002:"
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!startvote <timespan> <topic>\003' to begin a voting session."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Timespans is set as follows:"
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 XXm \= xxMinutes"
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 XXh \= xxHours"
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Example: \0034!startvote 24h Should we play a game\\?\003 for a 24 hour vote."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Example: \0034!startvote 200m Should we play a game\\?\003 for a 200 minute vote."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 \00312!!!NOT VALID!!!\003: \0034!startvote 24h 20m Should we play a game\\?\003."
	puthelp "PRIVMSG $nick :\002\|\00312Vote\003\|\002 Type: '\0034!vote\003' to display previous voting session's outcome."
}

###------------------------ Time Remaining Warning ------------------------###
proc tie_breaker {} {
global voting_chan vote_topic botnick vote_timestart vote_time
	if {$vote_time > 7200} {
		set vote_time 7200
		set vote_timestart [unixtime]
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 \00312 Tie Detected!! Extending voting time 2 Hours! Type !endvote to end this vote early"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 Vote open on: \002 $vote_topic\002"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002  \0034 [duration $vote_time]\003 left to vote"
		set voteset(t4) [utimer [expr $vote_time - 1200] vote_warning]
	} else {
		set vote_time 1800
		set vote_timestart [unixtime]
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 \00312 Tie Detected!! Extending voting time 30 Minutes! Type !endvote to end this vote early"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 Vote open on: \002 $vote_topic\002"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002  \0034 [duration $vote_time]\003 left to vote"
		set voteset(t4) [utimer [expr $vote_time - 900] vote_warning]
	}
	set voteset(t5) [utimer $vote_time "vote_results 1 2 3 4 5"]
}

###------------------------ Time Remaining Warning ------------------------###
proc vote_warning {} {
global voting_chan vote_topic botnick vote_timestart vote_time voting
	if {$voting == "yes"} {
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002 Vote open on: \002 $vote_topic\002"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
		puthelp "PRIVMSG $voting_chan :\002\|\00312Vote\003\|\002  \0034 [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]]\003 left to vote"
	}
}

###------------------------ Time Remaining Onjoin Reminder ------------------------###
proc vote_reminder {nick mask hand chan} {
global voting_chan vote_topic botnick voting vote_timestart vote_time voted_people
	set mask [maskhost $mask]
	if {[string match $chan $voting_chan] == 1 && [info exists voted_people($mask)] == 0 && [string match "yes" $voting] == 1} {
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002 Vote open on: \002 $vote_topic\002"
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002   '\0034/msg $botnick vote <yes/no> \[comments\]\003' or '\0034/msg $botnick vote help\003' for more commands"
		puthelp "NOTICE $nick :\002\|\00312Vote\003\|\002  \0034 [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]]\003 left to vote"
	}
}

###------------------------ Time Remaining Channel Trigger ------------------------###
proc vote_timer {nick mask hand chan text} {
global voting_chan vote_topic botnick voting vote_timestart vote_time voted_people
	if {$voting == "yes"} {
		puthelp "PRIVMSG $chan :\002\|\00312Vote\003\|\002  \0034 [duration [expr (([unixtime] - $vote_timestart) - $vote_time) * -1]]\003 left to vote"
	}
}


###------------------------ Write Votes to Temp File ------------------------###
proc setvote {chan topic begintime endtime} { global peak
   set chan [string tolower $chan]
   set peak($chan) "$curnum $unixtime"
   set fid [open "vote.$chan.txt" "WRONLY CREAT"]
   puts $fid $chan
   puts $fid $topic
   puts $fid $begintime
   puts $fid $endtime
   puts $fid "Voting Comments:"
}

###------------------------ Write Comments to Temp File ------------------------###
proc setcomment {comment} { global peak
   set chan [string tolower $chan]
   set peak($chan) "$curnum $unixtime"
   set fid [open "vote.$chan.txt" "WRONLY CREAT"]
   puts $fid $curnum
   puts $fid $unixtime
   close $fid
}

###------------------------ Host Masking Process ------------------------###
proc getmask {nick chan} {
  set mask [string trimleft [maskhost [getchanhost $nick $chan]] *!]
  set mask *!*$mask
  return $mask
}

putlog "\0033 Vote Script v1.15 (Written by Loki` #FTP4Warez) Loaded Succesfully"

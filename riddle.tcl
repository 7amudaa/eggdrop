#############################################################################################################
#                                                                                                           #
#                                         =:= Riddle.tcl by Leg =:=                                         #
#                                                                                                           #
# This script is inspired from one I saw running about 6-7 years ago in Undernet's #Vampires. Basically it  #
# gives the player a riddle and gives them 3 minutes to answer it. If they get it right they are opped      #
# for 1 hour, otherwise they get banned. It also bans people who answer it (correctly) in the main channel, #
# however it can't punish cheaters if they /msg the answer to the player (doh!). I remember it had a        #
# feature that let the player regain ops if they got banned, disconnected or left the channel, and it did   #
# so by assigning them a randomly generated password. I might add a feature like that in the next version.  #
# Please report any bugs (and fixes if you have any) to onelegguy at gmail dot com.                         #
#                                                                                                           #
# [ v1.0.1 updates ]                                                                                        #
#                                                                                                           #
# - deopping all non-ops opped by the winner by setting the channel +bitch temporarilly after 1 hour        #
#   (thanks to LordDragon for pointing it out)                                                              #
# - fixed a bug that allowed them to change nick, part or quit without being banned, even if they were      #
#   warned about it (after getting a right answer)                                                          #
# - enforcing predefined channel modes temporarily after the game is over, in case they set it +i, etc.     #
# - wrote xprot.tcl which is an extension to this script, I recommend you load that too along with this one #
#   (it will only allow winners to set so many bans and kick so many people before being deopped, and it    #
#   also protects the bot from deops/kicks/bans - it works through Undernet's X)                            #
#                                                                                                           #
# Trigger: !riddle (public)                                                                                 #
#                                                                                                           #
# To do:                                                                                                    #
#                                                                                                           #
# - (!) Possible "cheating" if they inject an "OR" statement in the answer?                                 #
# - Make it work on multiple channels                                                                       #
# - Add the password feature (maybe) - not likely, as it might prove to be just a security flaw             #
# - Come up with a riddle db (maybe)                                                                        #
#                                                                                                           #
# Thanks to:                                                                                                #
#                                                                                                           #
# - Cancer (http://www.undernetvampires.com/)                                                               #
# - DrN from Undernet's #RCS                                                                                #
# - LordDragon from Undernet's #Love                                                                        #
# - hwk, thommey, simple, paultwang and Guvnor from Undernet's #TCL and #Eggdrop                            #
#                                                                                                           #
# Tested on Eggdrop v1.6.19 / FreeBSD 6.1-STABLE / TCL 8.4.16                                               #
#                                                                                                           #
#>---------------------------------------------------------------------------------------------------------<#
#                                                                                                           #
#                  *****  IF YOU DON'T READ THIS CAREFULLY THE WORLD WILL END!  *****                       #
#                                                                                                           #
# The script needs a seperate file named "riddles.txt". It must be saved in your /eggdrop/scripts dir.      #
# It must contain the riddles and their answers in the following format:                                    #
# riddle 1*answer 1                                                                                         #
# the second riddle*answer 2                                                                                #
# This is the third riddle*the third answer goes here                                                       #
# ...etc                                                                                                    #
#                                                                                                           #
# DO NOT:                                                                                                   #
# - place more than one riddle on the same line                                                             #
# - use "*" in the riddle body or in the answer. "*" is to be used as a separator only, so the script can   #
#   tell which is the actual riddle and which is its answer.                                                #
# - leave any spaces between between the riddle body, the "*" separator and the answer. No spaces after the #
#   answer either. If you do, the script might not work as intended.                                        #
# - name the riddles file anything else but "riddles.txt"                                                   #
# - email me to ask for riddles or puzzles. You have google for that.                                       #
# - masturbate often. It cheapens the experience.                                                           #
#                                                                                                           #
# DO:                                                                                                       #
# - have AT LEAST one riddle in the "riddles.txt" file at all times. Otherwise the bot will crash.          #
# - run a protection script for the bot (preferably with Channel Services). Riddle.tcl can GIVE OPS TO      #
#   RANDOM PEOPLE IN YOUR CHANNEL if they get the answer right. I suggest using my xprot.tcl.               #
# - email me to report bugs and/or to suggest new features or improvements                                  #
#                                                                                                           #
#############################################################################################################

#Channel to work on.
set rchan "#yourchannel"

# Time in minutes to answer the riddle before kickban.
set mins 3

# If they fail, ban them for how many minutes?
set btime 60

# Kick reason when they fail.
set kreas "You've failed to answer the riddle. Goodbye."

# If they get it right, op them for how many minutes?
set otime 60

# If someone else guesses the correct answer and says it in the main channel they get banned.
# Enter the ban duration in minutes.
set chbtime 60

# ...and the kick reason.
set chkreas "You were told not to help them with the riddle. Goodbye."

set ver "v1.0.1"
set answered 0
set gameon 0
set answer ""
set rtxt ""
set player ""
set rbanmask ""
set chanclear "+tn-sprmilkDd"
set channormal "+tn"

if {![file exists scripts/riddles.txt]} {
 putlog "WARNING: riddles.txt not found (!riddle is disabled)"
 return
 }

bind pub - "!riddle" askriddle
proc askriddle {nick uhost hand chan rest} {
global botnick player answer answered mins otime btime gameon rtxt rbanmask rchan chanclear channormal
if {($gameon == 0) && ($chan == $rchan)} {
 set player $nick
 set rbanmask "*!*@[lindex [split $uhost @] 1]"
 set rfile "scripts/riddles.txt"
 set fd [open $rfile r]
 set lines [split [read -nonewline $fd] "\n"]
 set num [rand [llength $lines]]
 set randline [lindex $lines $num]
 set rtxt [lindex [split $randline *] 0]
 set answertemp [lindex [split $randline *] 1]
 set answer [string tolower $answertemp]
 close $fd
 puthelp "PRIVMSG $chan :$player: I will now ask you a riddle you will have to answer within $mins minutes."
 puthelp "PRIVMSG $chan :If you do you will be opped for $otime minutes."
 puthelp "PRIVMSG $chan :If you don't you will be banned for $btime minutes."
 puthelp "PRIVMSG $chan :If you disconnect, leave the channel or change your nick within the next $mins minutes you will be banned!"
 puthelp "PRIVMSG $chan :Anyone found to be helping $player will be banned! This is your ONLY warning!"
 puthelp "PRIVMSG $chan :\002Let it begin!\002"
 puthelp "PRIVMSG $chan :$rtxt"
 set gameon 1
 timer $mins "fail $player $rbanmask $rchan"
 bind pubm - "*$answer*" chkanswer
 proc chkanswer {nick uhost hand chan rest} {
 global botnick player answer answered otime chbtime chkreas gameon rchan chanclear channormal
 if {($chan == $rchan) && ([string tolower $rest] == $answer) && ($nick == $player) && ($gameon != 0)} { 
  set answered 1
  unbind pubm - "*$answer*" chkanswer
  puthelp "PRIVMSG $rchan :Congratulations $nick! The answer was '$answer'!"
  puthelp "PRIVMSG $rchan :You will now be opped on $rchan for the next $otime minutes!"
  puthelp "PRIVMSG $rchan :If you disconnect, leave the channel or change your nick within the next $otime minutes you will be banned!"
  puthelp "PRIVMSG $rchan :Have fun!"
  puthelp "MODE $rchan +o $player"

# Uncomment the following 6 lines (and edit the number of bans, kicks, etc.) if you're running xprot.tcl
  
  #puthelp "PRIVMSG $player :You may set no more than 3 bans and kick no more than 3 people."
  #puthelp "PRIVMSG $player :If any of these limits is reached you will be automatically deopped."
  #puthelp "PRIVMSG $player :You may NOT deop, kick or ban me at any time. If you do you will be automatically banned."
  #puthelp "PRIVMSG $player :Everything you do in the next $otime minutes is being logged."
  #puthelp "PRIVMSG $player :Any foolish behaviour will be handled accordingly by human operators."
  #puthelp "PRIVMSG $player :Thank you for playing !riddle :)"

  timer $otime [list putquick "MODE $rchan -o $player"]
  timer $otime [list channel set $rchan +bitch]
  timer $otime [list channel set $rchan chanmode $chanclear]
  timer $otime [list puthelp "PRIVMSG $rchan :The game has ended!"]
  timer $otime [list puthelp "PRIVMSG $player :$player: You may now disconnect, leave the channel or change your nick."]
  timer $otime [list set gameon 0]
  incr otime 2
  timer $otime [list channel set $rchan chanmode $channormal]
  timer $otime [list channel set $rchan -bitch]
  incr otime -2
  } elseif {($chan == $rchan) && ($nick != $player) && ($gameon != 0)} {
  set answered 1
  set gameon 0
  unbind pubm - "*$answer*" chkanswer
  set chmask "*!*@[lindex [split $uhost @] 1]"
  putquick "KICK $rchan $nick :$chkreas"
  putquick "MODE $rchan +b $chmask"
  newchanban $rchan $chmask riddle $chkreas $chbtime
  puthelp "PRIVMSG $rchan :The game has ended!"
  puthelp "PRIVMSG $rchan :$player: You may request a new !riddle if you still want to."
  }
 }} elseif {($gameon == 1) && ($chan == $rchan)} {
 puthelp "PRIVMSG $chan :$nick: A !riddle game is already in progress or someone guessed the answer. You have to wait until the game ends or until they are deopped. You are now ignored for 3 minutes."
 set ignmask "*!*@[lindex [split $uhost @] 1]"
 newignore $ignmask riddle riddleflood 3
 }
}

proc fail {nick uhost chan} {
global botnick answer answered btime gameon rbanmask rchan kreas
if {($answered == 0) && ($gameon != 0)} {
 bind pubm - "*$answer*" chkanswer
 unbind pubm - "*$answer*" chkanswer
 puthelp "PRIVMSG $rchan :The game has ended!"
 newchanban $rchan $rbanmask riddle $kreas $btime
 set gameon 0
 }
}

bind nick - * nickchange
proc nickchange {nick uhost hand chan rest} {
global botnick player answer btime gameon rbanmask rchan
set nickreas "You were told NOT to change your nick. Goodbye."
if {($chan == $rchan) && ($nick == $player) && ($gameon != 0)} {
 bind pubm - "*$answer*" chkanswer
 unbind pubm - "*$answer*" chkanswer
 set gameon 0
 puthelp "PRIVMSG $rchan :The game has ended!"
 newchanban $rchan $rbanmask riddle $nickreas $btime
 }
}

bind part - * leftchan
proc leftchan {nick uhost hand chan rest} {
global botnick player answer btime gameon rbanmask rchan
set partreas "You were told NOT to leave the channel while the game was in progress. Goodbye."
if {($chan == $rchan) && ($nick == $player) && ($gameon != 0)} {
 bind pubm - "*$answer*" chkanswer
 unbind pubm - "*$answer*" chkanswer
 set gameon 0
 puthelp "PRIVMSG $rchan :The game has ended!"
 newchanban $rchan $rbanmask riddle $partreas $btime
 }
}

bind sign - * rquit
proc rquit {nick uhost hand chan rest} {
global botnick player answer btime gameon rbanmask rchan
set quitreas "You were told NOT to quit while the game was in progress. Goodbye."
if {($chan == $rchan) && ($nick == $player) && ($gameon != 0)} {
 bind pubm - "*$answer*" chkanswer
 unbind pubm - "*$answer*" chkanswer
 set gameon 0
 puthelp "PRIVMSG $rchan :The game has ended!"
 newchanban $rchan $rbanmask riddle $quitreas $btime
 }
}

putlog "..:: Loaded \00312riddle.tcl\003 $ver by Leg ::.."

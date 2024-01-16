##################################################################################################
##                                                                                              ##
##  Author: Justdabomb2                         <email: edngravy@sbcglobal.net>                 ##
##  Script: Dice Game                                                                           ##
##  Version: v1.1                                                                               ##
##  Date: 10/22/2006                                                                            ##
##  Tested with: Eggdrop v1.6.18                                                                ##
##                                                                                              ##
##  Commands:     !dice - Turns the game on.                                                    ##
##                  - You have to turn the game on before you can do anything else.             ##
##                !play <nick> - Starts a game between you and the specified nick.              ##
##                !play bot - Starts agame between you and the bot.                             ##
##                !roll - Rolls the dice.                                                       ##
##                !diceoff - Turns the game off.                                                ##
##                !dicehelp - Shows the commands of the script.                                 ##
##                                                                                              ##
##                                                                                              ##
##  Installation:                                                                               ##
##                1. Save in your script directory as "dice.tcl".                               ##
##                2. add line "source scripts/dice.tcl to the bottom of your eggdrop            ##
##                   configuration file.                                                        ##
##                3. CTRL+F search for 'set dicechan ' and change "#channel" to the nane of     ##
##                   the channel you want the game to be played on.                             ##
##   (optional) - 4. CTRL+F search for 'set winmsgs' and change the messages below to what you  ##
##                   want them to say when a person wins.                                       ##
##   (optional) - 5. CTRL+F search for 'set losemsgs' and change the messages below to what you ##
##                   want it to say when a person loses.                                        ##
##   (optional) - 6. CTRL+F search for 'set dicetextcolor ' and change "1" to the color you     ##
##                   want to your bot use when the script is un use (use the color key below).  ##
##                7. Rehash or restart your bot, and type "!dice" in the channel.               ##
##                                                                                              ##
##                                                                                              ##
##  Bugs:         - None known yet, E-mail me if you find any.                                  ##
##                                                                                              ##
##                                                                                              ##
##  Color Key:                                                                                  ##
##                               ||=-------------=||=--------=||                                ##
##                               ||   Color Name  ||  Number  ||                                ##
##                               ||=-------------=||=--------=||                                ##
##                               || White         ||    0     ||                                ##
##                               || Black         ||    1     ||                                ##
##                               || Dark Blue     ||    2     ||                                ##
##                               || Green         ||    3     ||                                ##
##                               || Red           ||    4     ||                                ##
##                               || Brown         ||    5     ||                                ##
##                               || Purple        ||    6     ||                                ##
##                               || Orange        ||    7     ||                                ##
##                               || Yellow        ||    8     ||                                ##
##                               || Light Green   ||    9     ||                                ##
##                               || Teal          ||    10    ||                                ##
##                               || Light Blue    ||    11    ||                                ##
##                               || Blue          ||    12    ||                                ##
##                               || Pink          ||    13    ||                                ##
##                               || Dark Grey     ||    14    ||                                ##
##                               || Light Grey    ||    15    ||                                ##
##                               ||=-------------=||=--------=||                                ##
##                                                                                              ##
##                                                                                              ##
##  You do NOT need to change anything in this script (besides what it tells you to change in   ##
##             the installation), it should work the way it is right now.                       ##
##                                                                                              ##
##     Newer versions on this script will be if I decide something should be added or a bug     ##
##                                     needs to be fixed.                                       ##
##                                                                                              ##
##           If you notice any problems with the script, please e-mail them to me at            ##
##                                   edngravy@sbcglobal.net                                     ##
##                                                                                              ##
##                                                                                              ##
##  Please do not re-distribute a modified version of this script. If you do re-distribute      ##
##  it in it's original form, please give credit to me, and do not claim it as your own.        ##
##                                                                                              ##
##                                                                   ~Thank you!                ##
##                                                                                              ##
##################################################################################################

###############################################################
## Do NOT forget to change this to the name of your channel! ##
###############################################################

set dicechan "#dew"

#######################################################################
## Do NOT forget you can change this set a different color of text.  ##
#######################################################################

set dicetextcolor "1"

#########################################################
## Random messages your bot will use when a user wins. ##
#########################################################

set winmsgs {
  "Good job"
  "Congratulations"
  "Wowzers"
  "Now win again"
}

###########################################################
## Random messages your bot will use when a user losses. ##
###########################################################

set losemsgs {
  "Sorry."
  "Too bad."
  "Try again."
  "Keep trying."
}

#######################################################
## You do not need to edit anything below this line. ##
#######################################################

##################################################
##  Important variables, do not change please.  ##
##################################################

set maxsides "2 3 4 5 6 7 8 9 10 11 12"
set dicecreator "Justdabomb2"
set diceversion "v1.1"
set onplayer 0
set playerone ""
set playertwo ""
set playeroneroll ""
set playertworoll ""
set botplayerroll ""

##########################################
## Command variables used in messages.  ##
##########################################

set diceoncmd "!dice"
set playwithcmd "!play"
set dicerollcmd "!roll"
set diceoffcmd "!diceoff"
set dicehelpcmd "!dicehelp"

###############
## Commands  ##
###############

bind pub - !dice turnon:dice
bind pub - !play play:with
bind pub - !roll roll:dice
bind pub - !diceoff turnoff:dice
bind pub - !dicehelp help:dice

##########################################################
## This is where the '!dice' part of the script starts. ##
##########################################################

proc turnon:dice {nick host handle chan arg} { 
  global dicechan onplayer playerone playertwo dicetextcolor
  global diceoffcmd playwithcmd dicecreator diceversion
  if {[string tolower $chan] == [string tolower $dicechan]} {
    if { $onplayer == 1 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor \002$playerone\002 and \002$playertwo\002 are in a game right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor It is \002$playerone\002's turn."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoffcmd\002 to turn the game off."
    }
    if { $onplayer == 2 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor \002$playerone\002 and \002$playertwo\002 are in a game right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor It is \002$playertwo\002's turn."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoffcmd\002 to turn the game off."
    }
    if { $onplayer == 3 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor \002$playerone\002 is playing me right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoffcmd\002 to turn the game off."
    }
    if { $onplayer == 4 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor Dice is already on."
      putquick "PRIVMSG $chan :\003$dicetextcolor If you want to play with a friend, type \002$playwithcmd <friend>\002."
      putquick "PRIVMSG $chan :\003$dicetextcolor If you want to play with me, type \002$playwithcmd bot\002."
    }
    if { $onplayer == 0 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor \002$dicecreator\002's Dice Game $diceversion has just been turned on by $nick." 
      putquick "PRIVMSG $chan :\003$dicetextcolor If you want to play with a friend, type \002$playwithcmd <friend>\002."
      putquick "PRIVMSG $chan :\003$dicetextcolor If you want to play with me, type \002$playwithcmd bot\002."
      set onplayer 4
    }
    } else {
    putquick "PRIVMSG $chan :\003$dicetextcolor Sorry $nick, Dice is only played in \002$dicechan\002. Join that channel to play."
  }
}

#####################################################################
## This is where the '!play <nick/bot>' part of the script starts. ##
#####################################################################

proc play:with {nick host handle chan arg} { 
  global dicechan onplayer playerone playertwo playeroneroll playertworoll botplayeroll dicetextcolor
  global winmsgs losemsgs diceoncmd playwithcmd dicerollcmd
  if {[string tolower $chan] == [string tolower $dicechan]} {
    if { $onplayer == 0 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor Sorry $nick, the game is not on right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoncmd\002 to turn it on."
    }
    if { $onplayer == 1 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor \002$playerone\002 and \002$playertwo\002 are in a game right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor It is \002$playerone\002's turn."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoffcmd\002 to turn the game off."
    }
    if { $onplayer == 2 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor \002$playerone\002 and \002$playertwo\002 are in a game right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor It is \002$playertwo\002's turn."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoffcmd\002 to turn the game off."
    }
    if { $onplayer == 3 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor \002$playerone\002 is playing me right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoffcmd\002 to turn the game off."
    }
    if { $onplayer == 4 } {
      set diceplayertwo [lindex [split $arg] 0] 
      if {$diceplayertwo == ""} {
        putquick "PRIVMSG $chan :\003$dicetextcolor If you want to play with a friend, type \002$playwithcmd <friend>\002."
        putquick "PRIVMSG $chan :\003$dicetextcolor If you want to play with me, type \002$playwithcmd bot\002."
      }
      if {$diceplayertwo == "bot"} {
        set diceplayerone $nick
        set playerone $diceplayerone
        putquick "PRIVMSG $chan :\003$dicetextcolor $playerone, you are playing me."
        putquick "PRIVMSG $chan :\003$dicetextcolor It is your turn, \002$playerone\002. Type \002$dicerollcmd\002 to go."
        set onplayer 3
        } else {
        set diceplayerone $nick
        set playerone $diceplayerone
        set playertwo $diceplayertwo
        putquick "PRIVMSG $chan :\003$dicetextcolor \002$playerone\002 is playing against \002$playertwo\002."
        putquick "PRIVMSG $chan :\003$dicetextcolor It is \002$playerone\002's turn. Type \002$dicerollcmd\002 to go."
        set onplayer 1
      }
    }
    } else {
    putquick "PRIVMSG $chan :\003$dicetextcolor Sorry $nick, Dice is only played in \002$dicechan\002. Join that channel to play."
  }
}

##########################################################
## This is where the '!roll' part of the script starts. ##
##########################################################

proc roll:dice {nick host handle chan arg} { 
  global dicechan maxsides onplayer playerone playertwo playeroneroll playertworoll botplayeroll dicetextcolor
  global winmsgs losemsgs diceoncmd diceoffcmd playwithcmd dicerollcmd
  if {[string tolower $chan] == [string tolower $dicechan]} {
    if { $onplayer == 0 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor Sorry $nick, the game is not on right now."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$diceoncmd\002 to turn it on."
    }
    if { $onplayer == 1 } {
      if {[string tolower $nick] == [string tolower $playerone]} {
        set playeroneroll [lindex $maxsides [rand [llength $maxsides]]]
        putquick "PRIVMSG $chan :\003$dicetextcolor $playerone shakes the two dice in their hand and lets them go..."
        putquick "PRIVMSG $chan :\003$dicetextcolor $playerone, you rolled a \002$playeroneroll\002."
        putquick "PRIVMSG $chan :\003$dicetextcolor It is \002$playertwo\002's turn now. Type \002$dicerollcmd\002 to go."
        set onplayer 2
        } else {
        putquick "PRIVMSG $chan :\003$dicetextcolor It's not your turn. It's \002$playerone\002's turn."
      }
      return
    }
    if { $onplayer == 2 } {
      set winmsg [lindex $winmsgs [rand [llength $winmsgs]]]
      if {[string tolower $nick] == [string tolower $playertwo]} {
        set playertworoll [lindex $maxsides [rand [llength $maxsides]]]
        putquick "PRIVMSG $chan :\003$dicetextcolor $playertwo shakes the two dice in their hand and lets them go..."
        putquick "PRIVMSG $chan :\003$dicetextcolor $playertwo, you rolled a \002$playertworoll\002."
        if {[string tolower $playeroneroll] == [string tolower $playertworoll]} {
          putquick "PRIVMSG $chan :\003$dicetextcolor It was a draw."
          putquick "PRIVMSG $chan :\003$dicetextcolor Rematch?!"
          bind pubm -|- * rematch:friend
        }
        if {[string tolower $playeroneroll] > [string tolower $playertworoll]} {
          putquick "PRIVMSG $chan :\003$dicetextcolor $playerone is the winner. $winmsg, $playerone!"
          putquick "PRIVMSG $chan :\003$dicetextcolor Rematch?!"
          bind pubm -|- * rematch:friend
        }
        if {[string tolower $playeroneroll] < [string tolower $playertworoll]} {
          putquick "PRIVMSG $chan :\003$dicetextcolor $playertwo is the winner. $winmsg, $playertwo!"
          putquick "PRIVMSG $chan :\003$dicetextcolor Rematch?!"
          bind pubm -|- * rematch:friend
        }
        set onplayer 0
        } else {
        putquick "PRIVMSG $chan :\003$dicetextcolor It's not your turn. It's \002$playertwo\002's turn."
      }
    }
    if { $onplayer == 3 } {
      set winmsg [lindex $winmsgs [rand [llength $winmsgs]]]
      set losemsg [lindex $losemsgs [rand [llength $losemsgs]]]
      if {[string tolower $nick] == [string tolower $playerone]} {
        set playeroneroll [lindex $maxsides [rand [llength $maxsides]]]
        putquick "PRIVMSG $chan :\003$dicetextcolor You shake the two dice in you hand and lets them go..."
        putquick "PRIVMSG $chan :\003$dicetextcolor You rolled a \002$playeroneroll\002."
        set botplayerroll [lindex $maxsides [rand [llength $maxsides]]]
        putquick "PRIVMSG $chan :\003$dicetextcolor I rolled a \002$botplayerroll\002."
        if {[string tolower $playeroneroll] == [string tolower $botplayerroll]} {
          putquick "PRIVMSG $chan :\003$dicetextcolor It was a draw."
          putquick "PRIVMSG $chan :\003$dicetextcolor Rematch?!"
          bind pubm -|- * rematch:bot
        }
        if {[string tolower $playeroneroll] > [string tolower $botplayerroll]} {
          putquick "PRIVMSG $chan :\003$dicetextcolor You are the winner. $winmsg!"
          putquick "PRIVMSG $chan :\003$dicetextcolor Rematch?!"
          bind pubm -|- * rematch:bot
        }
        if {[string tolower $playeroneroll] < [string tolower $botplayerroll]} {
          putquick "PRIVMSG $chan :\003$dicetextcolor I am the winner. $losemsg."
          putquick "PRIVMSG $chan :\003$dicetextcolor Rematch?!"
          bind pubm -|- * rematch:bot
        }
        set onplayer 0
        } else {
        putquick "PRIVMSG $chan :\003$dicetextcolor You are not playing. \002$playerone\002 is!"
      }
    }
    } else {
    putquick "PRIVMSG $chan :\003$dicetextcolor Sorry $nick, Dice is only played in \002$dicechan\002. Join that channel to play."
  }
}

##########################################################################################
## This is where the part of the script that tells the bot to ask for a rematch starts. ##
##########################################################################################

proc rematch:friend {nick uhost handle channel args} {
  global dicechan onplayer playerone playertwo playeroneroll playertworoll botplayeroll dicerollcmd dicetextcolor
  set args [string tolower [string trim [stripcodes c $args] "{}" ]]
  switch [string tolower [lindex [split $args] 0]] {
    "yes"
    {
      set chan $dicechan
      putquick "PRIVMSG $chan :\003$dicetextcolor A rematch has been started."
      putquick "PRIVMSG $chan :\003$dicetextcolor It is \002$playerone\002's turn."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$dicerollcmd\002 to go."
      set onplayer 1
      unbind pubm -|- * rematch:friend
      return
    }
    "no"
    {
      set chan $dicechan
      set onplayer 0
      set playerone ""
      set playertwo ""
      set playeroneroll ""
      set playertworoll ""
      set botplayerroll ""
      putquick "PRIVMSG $chan :\003$dicetextcolor Dice has been turned off. Thanks for playing!"
      unbind pubm -|- * rematch:friend
      return
    }
  }
  return 0
}

proc rematch:bot {nick uhost handle channel args} {
  global dicechan onplayer playerone playertwo playeroneroll playertworoll botplayeroll dicerollcmd dicetextcolor
  set args [string tolower [string trim [stripcodes c $args] "{}" ]]
  switch [string tolower [lindex [split $args] 0]] {
    "yes"
    {
      set chan $dicechan
      putquick "PRIVMSG $chan :\003$dicetextcolor A rematch has been started."
      putquick "PRIVMSG $chan :\003$dicetextcolor It is your turn, \002$playerone\002."
      putquick "PRIVMSG $chan :\003$dicetextcolor Type \002$dicerollcmd\002 to go."
      set onplayer 3
      unbind pubm -|- * rematch:bot
      return
    }
    "no"
    {
      set chan $dicechan
      set onplayer 0
      set playerone ""
      set playertwo ""
      set playeroneroll ""
      set playertworoll ""
      set botplayerroll ""
      putquick "PRIVMSG $chan :\003$dicetextcolor Dice has been turned off. Thanks for playing!"
      unbind pubm -|- * rematch:bot
      return
    }
  }
  return 0
}

#############################################################
## This is where the '!diceoff' part of the script starts. ##
#############################################################

proc turnoff:dice {nick host handle chan arg} { 
  global dicechan onplayer playerone playertwo playeroneroll playertworoll botplayeroll dicetextcolor
  if {[string tolower $chan] == [string tolower $dicechan]} {
    if { $onplayer == 0 } {
      putquick "PRIVMSG $chan :\003$dicetextcolor Dice is already off."
      } else {
      putquick "PRIVMSG $chan :\003$dicetextcolor Dice has been turned off by $nick."
      set onplayer 0
      set playerone ""
      set playertwo ""
      set playeroneroll ""
      set playertworoll ""
      set botplayerroll ""
    }
    } else {
    putquick "PRIVMSG $chan :\003$dicetextcolor Sorry $nick, Dice is only played in \002$dicechan\002. Join that channel to play."
  }
}

##############################################################
## This is where the '!dicehelp' part of the script starts. ##
##############################################################

proc help:dice {nick host handle chan arg} { 
  global dicechan diceoncmd playwithcmd dicerollcmd diceoffcmd dicehelpcmd dicetextcolor
  if {[string tolower $chan] == [string tolower $dicechan]} {
    putquick "PRIVMSG $chan :\003$dicetextcolor \002$diceoncmd \002- Turns the game on."
    putquick "PRIVMSG $chan :\003$dicetextcolor \002$playwithcmd <nick> \002- Starts a game between you and <nick>."
    putquick "PRIVMSG $chan :\003$dicetextcolor \002$playwithcmd bot \002- Starts agame between you and me."
    putquick "PRIVMSG $chan :\003$dicetextcolor \002$dicerollcmd \002- Rolls the dice."
    putquick "PRIVMSG $chan :\003$dicetextcolor \002$diceoffcmd \002- Turns the game off."
    putquick "PRIVMSG $chan :\003$dicetextcolor \002$dicehelpcmd \002- Shows this help menu."
    } else {
    putquick "PRIVMSG $chan :\003$dicetextcolor Sorry $nick, Dice is only played in \002$dicechan\002. Join that channel to play."
  }
}

putlog "$dicecreator's Dice Script $diceversion Loaded"

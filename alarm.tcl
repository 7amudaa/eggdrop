# Version: 1.0 beta
# Copyright © 2005 stalker
# Look for updates @ www.IRCWorld.ru
# Command format !alarm <time> <text> or !remind <time> <text>
# After passing  <time> bot will send you <text> in private and in notice

# Hear you can set the prefix for commands (reaction on .alarm or !alarm). You may use any symbol:
set cmdpr "!"
#Max.time of reminding in minutes
set alarm(time) "300"
#Max. number of reminders
set alarm(lim) "20"

bind pubm - "* ${cmdpr}help alarm*" :alarm:help
bind msgm - "${cmdpr}alarm*" :alarm:sets:timer
bind msgm - "${cmdpr}reminders" :alarm:list
bind msgm - "${cmdpr}forget" :alarm:delete
bind part - * :alarm:part
bind sign - * :alarm:part
bind join - * :alarm:join

proc :alarm:help {nick uhost hand chan text} {
        global alarm cmdpr
        if {![validuser $hand]} { return }
        puthelp "privmsg $nick :Commands are writing into bot's private" -next
        puthelp "privmsg $nick :\002${cmdpr}alarm \[minutes\] \[text\]\002 - Set after how much \002minutes\002(not more than $alarm(time)) bot will say into your private  \002text\002;"
        puthelp "privmsg $nick :\002${cmdpr}forget\002 - Delete reminder;"
        if {[matchattr $hand o]} { puthelp "privmsg $nick :\002${cmdpr}reminders\002 - View the list of active reminders." }
        return
}

proc :alarm:sets:timer {nick uhost hand text} {
        if {![validuser $hand] || ![handonchan $hand]} { return }
        global alarm
        set l 0
        foreach i [timers] {
                if {[string range [lindex $i 1] 0 5] == "altim:"} {
                        incr l
                }
        }
        if {$l > $alarm(lim)} {
                puthelp "privmsg $nick :\00312Sorry, can not set reminder now, try again later"
                return
        }
        set mins [expr int(abs({[lindex $text 1]}))]
        if {![isnumber $mins]} {
                puthelp "privmsg $nick :\002Time\002 is not set"
                return
        }
        if {$mins > $alarm(time)} { 
                puthelp "privmsg $nick :\00314No...it's a very long time to wait. Max. \002$alarm(time) minutes."
                return
        }
        set notice [lrange $text 2 end]
        if {$notice == ""} {
                puthelp "privmsg $nick :\002Text\002 must be\002 set"
                return
        }
        if {[regexp -nocase -- \{.*?\ altim:$hand\ (timer.*?)\} [timers] g id]} {
                killtimer $id
                rename altim:$hand ""
        }
        setuser $hand XTRA notice $notice
        timer $mins [list altim:$hand]
        proc altim:$hand { } {
                set procname [lindex [info level 0] 0]
                set hand [lindex [split $procname ":"] 1]
                if {[hand2nick $hand] != ""} {
                                putserv "privmsg [hand2nick $hand] :[getuser $hand XTRA notice]" 
                                putserv "notice [hand2nick $hand] :[getuser $hand XTRA notice]"
                                utimer 5 [list putserv "notice [hand2nick $hand] :[getuser $hand XTRA notice]"]
                                utimer 10 [list putserv "notice [hand2nick $hand] :[getuser $hand XTRA notice]"]
                        }
                rename $procname ""
                setuser $hand XTRA notice ""
        }
        puthelp "privmsg $nick :\00303Ok, I will call you in \002$mins\002 minutes"
        return
}

proc :alarm:list {nick uhost hand text} {
if {![matchattr $hand o]} {return } 
        foreach i [timers] {
                if {[string range [lindex $i 1] 0 5] == "altim:"} {
                        lappend out "\00310[hand2nick [string range [lindex $i 1] 6 end]]\00314(\00305[lindex $i 0]\00314)" 
                }
        }
        if {[info exists out]} {
                if {[llength $out] == 1} { set al "reminder" } elseif {[llength $out] < 5} { set al "reminders" } else {
set al "reminders" }
                puthelp "privmsg $nick :\00314Total\00304 [llength $out]\00314 $al."
                puthelp "privmsg $nick :\00314They were set - [join $out ","]."
        } else {
                puthelp "privmsg $nick :\00314No active reminders now"
        }
        return
}

proc :alarm:delete {nick uhost hand text} {
        if {![validuser $hand]} { return }
        if {[regexp -nocase -- \{.*?\ altim:$hand\ (timer.*?)\} [timers] g id]} {
                killtimer $id
                rename altim:$hand ""
                puthelp "privmsg $nick :\00314Reminder was deleted"
        }
        return
} 
        
proc :alarm:part {nick uhost hand chan text} {
utimer 1 [list :alarm:partoff $hand]
}

proc :alarm:partoff {hand} {
        if {![handonchan $hand]} {
                foreach i [timers] {
                                if {[string first "altim:$hand" [lindex $i 1]] != -1} {
                                utimer 60 "[list :alarm:del [lindex $i 2] $hand]"
                        }
                }
        }
}

proc :alarm:del {id hand} {
        killtimer $id
        rename altim:$hand ""
        return
}
proc :alarm:join {nick uhost hand chan} {
        foreach i [utimers] {
                if {[string match ":alarm:del timer* $hand" "[lindex $i 1]"]} {
                                killutimer [lindex $i 2]
        }
}
}
putlog "Alarm script by stalker loaded"

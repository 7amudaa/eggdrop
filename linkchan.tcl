# Linkchan by BarkerJr <barkerjr@clancdg.com>
#If you enjoy this script, please consider emailing me.
#
#
#known bugs:
#
#text said in the remote channel starting with a :
#will be relayed without the :
#(the rest of the msg will still be there)
#
#clears the help que when it sees itself talking (atempts to stop floods on netsplit rejoins)

set debug 1
set debug_out 1
set shortcommands 1

bind dcc m linkchan dcc:linkchan
if {$shortcommands == 1} {bind dcc m lc dcc:linkchan}
proc dcc:linkchan {hand idx arg} {
 global nick realname username chanlinkchan chanlinkidx chanlinkserv chanlinknet chanlinknick shortcommands linkchantrim
 set chanlinknick $nick[rand 1000]
 set chan [lindex $arg 0]
 set net [lindex $arg 1]
 set serv [lindex $arg 2]
 set port [lindex $arg 3]
 if {![validchan $chan]} {
  putdcc $idx "Invalid Channel"
  putdcc $idx "usage: .linkchan <channel> <network> <server> \[port\]"
 } else {
  if {$serv == ""} {
   putdcc $idx "Specify a Server"
   putdcc $idx "usage: .linkchan <channel> <network> <server> \[port\]"
  } else {
   if {[info exists chanlinkidx]} {
    if {[valididx $chanlinkidx]} {
     putdcc $chanlinkidx "QUIT :Switching Servers"
     killdcc $chanlinkidx
    }
   }
   if {$port == ""} {
    set chanlinkidx [connect $serv 6667]
   } else {
    if {$port != ""} {set chanlinkidx [connect $serv $port]}
   }
   set chanlinkchan $chan
   set chanlinkserv $serv
   set chanlinknet $net
   control $chanlinkidx linkchan
   putlc "USER $username 0 0 :$realname"
   putlc "NICK :$chanlinknick"
   set linkchantrim "abcdefghijklmnopqrstuvwxyzABCDEFGHIJGKLMNOPQRSTUVWXYZ1234567890 !@*.#~-_|\[\]\{\}`"
   bind part - * part:chanlink
   bind pubm - * pubm:chanlink
   bind sign - * sign:chanlink
   bind ctcp - ACTION ctcp:chanlink
   bind join - * join:chanlink
   bind nick - * nick:chanlink
   bind dcc m -linkchan dcc:-linkchan
   bind dcc m dumplinkchan dcc:dumplinkchan
   if {$shortcommands == 1} {
    bind dcc m -lc dcc:-linkchan
    bind dcc m dumplc dcc:dumplinkchan
   }
   return 1
  }
 }
}

proc dcc:dumplinkchan {hand idx arg} {
 putlc $arg
 return 1
}

proc dcc:-linkchan {hand idx arg} {
 global chanlinkidx chanlinkchan chanlinkserv chanlinknet linkchantrim shortcommands
 putlc "QUIT :Shutting Down Link"
 killdcc $chanlinkidx
 linkchan:shutdown
 return 1
}

proc linkchan:shutdown {} {
 global chanlinkidx chanlinkchan chanlinkserv chanlinknet linkchantrim shortcommands
 unset chanlinkidx
 unset chanlinkchan
 unset chanlinkserv
 unset chanlinknet
 unset linkchantrim
 unbind part - * part:chanlink
 unbind pubm - * pubm:chanlink
 unbind sign - * sign:chanlink
 unbind ctcp - ACTION ctcp:chanlink
 unbind join - * join:chanlink
 unbind nick - * nick:chanlink
 unbind dcc m -linkchan dcc:-linkchan
 unbind dcc m dumplinkchan dcc:dumplinkchan
 clearqueue help
 if {$shortcommands == 1} {
  unbind dcc m -lc dcc:-linkchan
  unbind dcc m dumplc dcc:dumplinkchan
 }
}

proc putlc {arg} {
 global chanlinkidx debug_out
 if {$debug_out == 1} {putlog "linkchan> $arg"}
 putdcc $chanlinkidx $arg
}

proc linkchan {idx arg} {
 global debug nick chanlinkchan chanlinknet chanlinknick username realname linkchantrim
 if {$debug == 1} {putlog "linkchan< $arg"}
 set arg2 [lindex $arg 0]
 switch $arg2 {
  PING {putlc "PONG [lindex $arg 1]"}
  ERROR {
   putserv "PRIVMSG $chanlinkchan :\0032ERROR: Closing Link"
   linkchan:shutdown
  }
 }
 switch [lindex $arg 1] {
  001 {
   putlc "MODE $chanlinknick :+i"
   putlc "JOIN $chanlinkchan"
  }
  433 {
   set chanlinknick $nick[rand 1000]
   putdcc $idx "NICK :$chanlinknick"
  }
  353 {puthelp "privmsg $chanlinkchan :$chanlinknet NAMES list: [string trimleft [string trimleft [string trimleft $arg :] "abcdefghijklmnopqrstuvwxyzABCDEFGHIJGKLMNOPQRSTUVWXYZ1234567890 !@*.#~-_|\[\]\{\}`="] :]"}
  JOIN {puthelp "privmsg $chanlinkchan :\0033*** [lindex [split [lindex [split $arg2 !] 0] :] 1]@$chanlinknet ([lindex [split $arg2 !] 1]) has joined $chanlinkchan"}
  KICK {linkchan:kick $idx $arg}
  NICK {puthelp "privmsg $chanlinkchan :\0033*** [lindex [split [lindex [split $arg2 !] 0] :] 1]@$chanlinknet in now known as [string trimleft [lindex $arg 2] :]@$chanlinknet"}
  PART {puthelp "privmsg $chanlinkchan :\0033*** [lindex [split [lindex [split $arg2 !] 0] :] 1]@$chanlinknet ([lindex [split $arg2 !] 1]) has left $chanlinkchan"}
  PRIVMSG {linkchan:privmsg $idx $arg}
  QUIT {puthelp "privmsg $chanlinkchan :\0032*** [lindex [split [lindex [split $arg2 !] 0] :] 1]@$chanlinknet ([lindex [split $arg2 !] 1]) Quit ([string trimleft [string trimleft [string trimleft $arg :] $linkchantrim] :])"}
 }
}

proc linkchan:privmsg {idx arg} {
 global chanlinkchan chanlinknet linkchantrim botnick network
 set nick [lindex [split [lindex [split $arg !] 0] :] 1]
 if {$nick == $botnick} {
  putlc "QUIT :Yikes! Am I looking in a Mirror?"
  killdcc $idx
  linkchan:shutdown
 } else {
  if {[string tolower [lindex $arg 2]] == [string tolower $chanlinkchan]} {
   set text [string trimleft [string trimleft [string trimleft $arg :] $linkchantrim] :]
   if {[string match \001*\001 $text]} {
    if {[string match \001ACTION*\001 $text]} {
     puthelp "privmsg $chanlinkchan :\0036 * $nick@$chanlinknet[string trimright [string trimleft [string trimleft $text \001ACTION] ""] \001]"
    }
   } else {
    if {[string match -nocase [lindex $text 0] !names]} {
     putlc "PRIVMSG $chanlinkchan :$network NAMES list: [chanlist $chanlinkchan]"
    } else {
     puthelp "privmsg $chanlinkchan :<$nick@$chanlinknet> $text"
    }
   }
  }
 }
}

proc linkchan:kick {idx arg} {
 global chanlinknick chanlinkchan
 if {$chanlinknick == [lindex $arg 3]} {putlc "JOIN $chanlinkchan"}
}

proc join:chanlink {nick uhost hand chan args} {
 global network chanlinkidx chanlinkchan
 if {[info exists chanlinkidx] && [string match [string tolower $chan] [string tolower $chanlinkchan]]} {
  if {[valididx $chanlinkidx]} {putlc "PRIVMSG $chan :\0033*** $nick@$network ($uhost) has joined $chan"}
 }
}

proc part:chanlink {nick uhost hand chan msg} {
 global network chanlinkidx chanlinkchan
 if {[info exists chanlinkidx] && [string match [string tolower $chan] [string tolower $chanlinkchan]]} {
  if {$msg != ""} {set msg ($msg)}
  if {[valididx $chanlinkidx]} {putlc "PRIVMSG $chan :\0033*** $nick@$network ($uhost) has left $chan $msg"}
 }
}

proc pubm:chanlink {nick uhost hand chan text} {
 global network chanlinkidx chanlinkchan chanlinknick
 if {$nick == $chanlinknick} {
  putlc "QUIT :Yikes! Am I looking in a Mirror?"
  killdcc $idx
  linkchan:shutdown
 } else {
  if {[info exists chanlinkidx] && [string match [string tolower $chan] [string tolower $chanlinkchan]]} {
   if {[valididx $chanlinkidx]} {
    if {[string match -nocase [lindex $text 0] !names]} {
     putlc "NAMES $chan"
    } else {
     putlc "PRIVMSG $chan :<$nick@$network> $text"
    }
   }
  }
 }
}

proc sign:chanlink {nick uhost hand chan reason} {
 global network chanlinkidx chanlinkchan
 if {[info exists chanlinkidx] && [string match [string tolower $chan] [string tolower $chanlinkchan]]} {
  if {[valididx $chanlinkidx]} {putlc "PRIVMSG $chan :\0032*** $nick@$network ($uhost) Quit ($reason)"}
 }
}

proc ctcp:chanlink {nick uhost hand dest keywork arg} {
 global network chanlinkidx chanlinkchan
 if {[info exists chanlinkidx]} {
  if {[valididx $chanlinkidx] && [string match [string tolower $dest] [string tolower $chanlinkchan]]} {
   putlc "PRIVMSG $dest :\0036 * $nick@$network $arg"
  }
 }
}

proc nick:chanlink {nick uhost hand chan newnick} {
 global network chanlinkidx chanlinkchan
 if {[info exists chanlinkidx] && [string match [string tolower $chan] [string tolower $chanlinkchan]]} {
  if {[valididx $chanlinkidx]} {putlc "PRIVMSG $chan :\0033*** $nick@$network is now known as $newnick@$network"}
 }
}

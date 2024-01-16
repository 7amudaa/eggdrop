#  ~> Version 1.0.0.1 (16.05.2006)
#       Fixed a little Bug (changed continue to return) (it makes trouble
        in the partyline)

#  ~> Version 1.0.0.0 (26.03.2006)
#       Script released.

#  --------------------------------------------------------------------------
#                       E    N    G    L    I    S    H
#  --------------------------------------------------------------------------
                                                                             
#  after you have installed this script, you'll have to rehash or restart    
#  the bot. When you finished that mission, you'll get every account with    
#  "<your admincommand> help"                                                
                                                                             
#  If you load that script for the first time, the language is set automatic 
#  to english. If you want to set the language to e.g. german, you'll have   
#  to write the command, which i write in the first "box".                   
                                                                             
#  --------------------------------------------------------------------------
#                       D    E    U    T    S    C    H                      
#  --------------------------------------------------------------------------

#  Nachdem du dieses Script installiert hast, so musst du dein Eggdrop oder
#  Windrop rehashen oder restarten. Wenn du dieses erfolgreich absolviert
#  hast, so bekommst du weitere Informationen  ber den Befehl
#  "<dein Admincommand> help"

#  Wenn du das Script zum ersten Mal l dst, so wird die Sprache automatisch
#  auf Englisch gesetzt sein. Dies kannst du aber  ndern, indem du den oben
#  genannten Befehl ausf hrst und dir dann die Auflistung anschaust.

#  --------------------------------------------------------------------------

#  ((( settings

      set 8ball(trigger)       "!8ball"
      set 8ball(trigger-admin) "\$8ball"
      set 8ball(author)        "lilmoe on \002(\002#dew on Undernet\002)\002"
      set 8ball(version)       "6.9"

#  )))

#  ((( bindings

      bind pub  -|-  "$8ball(trigger)"       8ball
      bind pub mn|mn "$8ball(trigger-admin)" 8ball:admin

#  )))

#  ((( setudef

      setudef flag 8ball
      setudef str  8ball-lang
      setudef int  8ball-counter

#  )))

#  --------------------------------------------------------------------------
#             !!! DO NOT CHANGE SOMETHING BELOW THESE LINES !!!
#  --------------------------------------------------------------------------

proc 8ball { nickname hostname handle channel arguments } {
global 8ball
set 8ball($channel) "[join [lrange [split $arguments] 0 end]]"
set 8ball(nr) "[rand 4]"
  if {![channel get $channel "8ball"]} {
    return
  } elseif {[channel get $channel "8ball-lang"] == "german"} { 
    if {$8ball($channel) == ""} {
      putserv "notice $nickname :\037\0034Fehler\037\003\002:\002 Du hast keine Frage gestellt!"
    } else {
      channel set $channel 8ball-counter [expr [channel get $channel "8ball-counter"] + 1]
      if {$8ball(nr) == "0"} {
        putserv "privmsg $channel :Frage Nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Antwort: Ja!"
      } elseif {$8ball(nr) == "1"} {
        putserv "privmsg $channel :Frage Nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Antwort: Nein!"
      } elseif {$8ball(nr) == "2"} {
        putserv "privmsg $channel :Frage Nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Antwort: Ich denke schon!"
      } elseif {$8ball(nr) == "3"} {
        putserv "privmsg $channel :Frage Nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Antwort: Ich denke eher nicht!"
      }
    }
  } elseif {[channel get $channel "8ball-lang"] == "english"} {
    if {$8ball($channel) == ""} {
      putserv "notice $nickname :\037\0034Error\0034\037\002:\002 you didnt ask a question!"
    } else {
      channel set $channel "8ball-counter" [expr [channel get $channel "8ball-counter"] + 1]
      if {$8ball(nr) == "0"} {
        putserv "privmsg $channel :Question nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Answer: yes!"
      } elseif {$8ball(nr) == "1"} {
        putserv "privmsg $channel :Question nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Answer: no!"
      } elseif {$8ball(nr) == "2"} {
        putserv "privmsg $channel :Question nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Answer: i think so ..."
      } elseif {$8ball(nr) == "3"} {
        putserv "privmsg $channel :Question nr. [channel get $channel "8ball-counter"]: $8ball($channel)"
        putserv "privmsg $channel :Answer: I dont think so ..."
      }
    }
  }
}

proc 8ball:admin { nickname hostname handle channel arguments } {
global 8ball
set 8ball(admin:$channel) "[join [lrange [split $arguments] 0 end]]"
  if {[channel get $channel "8ball-lang"] == ""} {
    channel set $channel 8ball-lang english
    putserv "notice $nickname :\037German\037\002:\002 Die Sprache wurde gerade auf \037Englisch\037 gesetzt. Bitte wiederhole noch einmal den Befehl."
    putserv "notice $nickname :\037English\037\002:\002 The language was set to \037english\037. Please retry the command."
  } elseif {[channel get $channel "8ball-lang"] == "german"} {
    if {$8ball(admin:$channel) == ""} {
      putserv "notice $nickname :bitte benutze $8ball(trigger-admin) \037help\037."
      putserv "notice $nickname :8ball.tcl - version $8ball(version) by $8ball(author)"
    } elseif {$8ball(admin:$channel) == "help"} {
      putserv "notice $nickname :$8ball(trigger-admin) \037status\037 \002(\002on/off\002)\002"
      putserv "notice $nickname :$8ball(trigger-admin) \037language\037 \002(\002german/english\002)\002"
      putserv "notice $nickname :$8ball(trigger-admin) \037version\037"
      putserv "notice $nickname :$8ball(trigger-admin) \037contact\037"
      putserv "notice $nickname :-- End of list --"
    } elseif {$8ball(admin:$channel) == "status"} {
      if {[channel get $channel "8ball"]} {
        putserv "notice $nickname :\037Status\037\002:\002 8ball.tcl ist in $channel aktiviert."
        putserv "notice $nickname :um es zu deaktivieren, so benutze doch bitte $8ball(trigger-admin) \037status off\037."
      } elseif {![channel get $channel "8ball"]} {
        putserv "notice $nickname :\037Status\037\002:\002 8ball.tcl ist in $channel deaktiviert."
        putserv "notice $nickname :um es zu aktivieren, so benute doch bitte $8ball(trigger-admin) \037status on\037."
      }
    } elseif {$8ball(admin:$channel) == "status on"} {
      if {[channel get $channel "8ball"]} {
        putserv "notice $nickname :\037\0034Fehler\003\037\002:\002 8ball ist schon in $channel aktiviert."
      } elseif {![channel get $channel "8ball"]} {
        channel set $channel +8ball
        putserv "notice $nickname :\037\0039Erfolgreich\003\037\002:\002 8ball wurde in $channel aktiviert."
      }
    } elseif {$8ball(admin:$channel) == "status off"} {
      if {![channel get $channel "8ball"]} {
        putserv "notice $nickname :\037\0034Fehler\003\037\002:\002 8ball ist schon in $channel deaktiviert."
      } elseif {[channel get $channel "8ball"]} {
        channel set $channel -8ball
        putserv "notice $nickname :\037\0039Erfolgreich\003\037\002:\002 8ball wurde in $channel deaktiviert."
      }
    } elseif {$8ball(admin:$channel) == "language"} {
      if {[channel get $channel "8ball-lang"] == "german"} {
        putserv "notice $nickname :\037Status\037\002:\002 momentan ist die Sprache \037Deutsch\037 aktiviert."
      } elseif {[channel get $channel "8ball-lang"] == "english"} {
        putserv "notice $nickname :\037Status\037\002:\002 momentan ist die Sprache \037Englisch\037 aktiviert."
      }
    } elseif {$8ball(admin:$channel) == "language german"} {
      if {[channel get $channel "8ball-lang"] == "german"} {
        putserv "notice $nickname :\037\0034Fehler\003\037\002:\002 die Sprache ist schon auf \037Deutsch\037 eingestellt."
      }
    } elseif {$8ball(admin:$channel) == "language english"} {
      if {[channel get $channel "8ball-lang"] == "german"} {
        channel set $channel 8ball-lang english
        putserv "notice $nickname :\037\0039Done\003\037\002:\002 the language was set to \037english\037."
      }
    } elseif {$8ball(admin:$channel) == "version"} {
      putserv "notice $nickname :\0378ball.tcl\037\002:\002 version $8ball(version) by $8ball(author)"
    } elseif {$8ball(admin:$channel) == "contact"} {
      putserv "notice $nickname :contact:"
      putserv "notice $nickname :\037IRC\037\002:\002 #miCHa on QuakeNet \002(\002www.QuakeNet.org\002)\002"
      putserv "notice $nickname :\037ICQ\037\002:\002 247-465-459 \002(\002nur f r Freunde - 95% der Kontakthinzuf gungen werden abgelehnt - sorry\002)\002"
      putserv "notice $nickname :\037Web\037\002:\002 www.miCHa.es"
      putserv "notice $nickname :\037Mail\037\002:\002 miCHa@miCHa.es"
      putserv "notice $nickname :-- End of list --"
    }
  } elseif {[channel get $channel "8ball-lang"] == "english"} {
    if {$8ball(admin:$channel) == ""} {
      putserv "notice $nickname :please use $8ball(trigger-admin) \037help\037."
      putserv "notice $nickname :8ball.tcl - version $8ball(version) by $8ball(author)"
    } elseif {$8ball(admin:$channel) == "help"} {
      putserv "notice $nickname :$8ball(trigger-admin) \037status\037 \002(\002on/off\002)\002"  
      putserv "notice $nickname :$8ball(trigger-admin) \037language\037 \002(\002german/english\002)\002"
      putserv "notice $nickname :$8ball(trigger-admin) \037version\037"
      putserv "notice $nickname :$8ball(trigger-admin) \037contact\037"
      putserv "notice $nickname :-- End of list --"
    } elseif {$8ball(admin:$channel) == "status"} {
      if {[channel get $channel "8ball"]} {
        putserv "notice $nickname :\037Status\037\002:\002 8ball.tcl is enabled in $channel."
        putserv "notice $nickname :please use $8ball(trigger-admin) \037status off\037 to disable it."
      } elseif {![channel get $channel "8ball"]} {
        putserv "notice $nickname :\037Status\037\002:\002 8ball.tcl is disabled in $channel."
        putserv "notice $nickname :please use $8ball(trigger-admin) \037status on\037 to enable it."
      }
    } elseif {$8ball(admin:$channel) == "status on"} {
      if {[channel get $channel "8ball"]} {
        putserv "notice $nickname :\037\0034Error\003\037\002:\002 8ball is already enabled in $channel."
      } elseif {![channel get $channel "8ball"]} {
        channel set $channel +8ball
        putserv "notice $nickname :\037\0039Done\003\037\002:\002 8ball is now enabled in $channel."
      }
    } elseif {$8ball(admin:$channel) == "status off"} {
      if {![channel get $channel "8ball"]} {
        putserv "notice $nickname :\037\0034Error\003\037\002:\002 8ball is already disabled in $channel."
      } elseif {[channel get $channel "8ball"]} {
        channel set $channel -8ball
        putserv "notice $nickname :\037\0039Done\003\037\002:\002 8ball is now disabled in $channel."
      }
    } elseif {$8ball(admin:$channel) == "language"} {
      if {[channel get $channel "8ball-lang"] == "english"} {
        putserv "notice $nickname :\037Status\037\002:\002 \037English\037 is the current language."
      } elseif {[channel get $channel "8ball-lang"] == "german"} {
        putserv "notice $nickname :\037Status\037\002:\002 \037German\037 is the current language."
      }
    } elseif {$8ball(admin:$channel) == "language english"} {
      if {[channel get $channel "8ball-lang"] == "english"} {
        putserv "notice $nickname :\037\0034Error\003\037\002:\002 \037English\037 is already the current language."
      }
    } elseif {$8ball(admin:$channel) == "language german"} {
      if {[channel get $channel "8ball-lang"] == "english"} {
        channel set $channel 8ball-lang german
        putserv "notice $nickname :\037\0039Erfolgreich\003\037\002:\002 Die Sprache wurde erfolgreich auf \037Deutsch\037 gesetzt."
      }
    } elseif {$8ball(admin:$channel) == "version"} {
      putserv "notice $nickname :\0378ball.tcl\037\002:\002 version $8ball(version) by $8ball(author)"
    } elseif {$8ball(admin:$channel) == "contact"} {
      putserv "notice $nickname :contact:"
      putserv "notice $nickname :\037IRC\037\002:\002 #miCHa on QuakeNet \002(\002www.QuakeNet.org\002)\002"
      putserv "notice $nickname :\037ICQ\037\002:\002 247-465-459 \002(\002thats only for friends - 95% of all requests are declined - sorry\002)\002"
      putserv "notice $nickname :\037Web\037\002:\002 www.miCHa.es"
      putserv "notice $nickname :\037Mail\037\002:\002 miCHa@miCHa.es"
      putserv "notice $nickname :-- End of list --"
    } 
  }
}

putlog "8ball.tcl loaded - version $8ball(version) by $8ball(author)"

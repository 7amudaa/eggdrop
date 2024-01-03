set dnshost(cmdchar) "!"


#-----------------please don't CHANGE ANY OF THE FOLLOWING LINES----------------------
bind pub - [string trim $dnshost(cmdchar)]dns dns:res
bind pub n|n [string trim $dnshost(cmdchar)]amsg pub:amsg
bind pub n|n [string trim $dnshost(cmdchar)]ame pub:ame
bind pub - [string trim $dnshost(cmdchar)]whois pub:host
bind pub - [string trim $dnshost(cmdchar)]dnsver pub:ver
bind pub - [string trim $dnshost(cmdchar)]dnsnick dns:nick
bind raw * 311 raw:host
#bind raw * 401 raw:fail

set dns_chan ""
set dns_host ""
set dns_nick ""
set dns_bynick ""

proc pub:host {nick uhost hand chan arg} {
global dns_chan
set dns_chan "$chan"
putserv "WHOIS [lindex $arg 0]"
}

proc raw:host {from signal arg} {
global dns_chan dns_nick dns_host dns_bynick
set dns_nick "[lindex $arg 1]"
set dns_host "*!*[lindex $arg 2]@[lindex $arg 3]"
foreach dns_say $dns_chan { puthelp "PRIVMSG $dns_say :User@host $dns_nick is $dns_host ." }
if {$dns_bynick == "oui"} {
                set hostip [split [lindex $arg 3] ]
                dnslookup $hostip resolve_rep $dns_chan $hostip
                set dns_bynick "non"
}
}

proc raw:fail {from signal arg} {
global dns_chan
set arg "[lindex $arg 1]"
foreach dns_say $dns_chan { puthelp "PRIVMSG $dns_say :$arg: No such nick" }
}

proc pub:ver {nick uhost hand chan text} {
putserv "PRIVMSG $chan : Dns Resolver by terroris aka Ryo"
}

proc pub:ame {nick uhost hand chan rest} {
set arg "[lrange $rest 0 end]"
foreach ame [channels] { puthelp "PRIVMSG $ame :\001ACTION $rest\001" }
return 0
}

proc pub:amsg {nick uhost hand chan rest} {
set rest "[lrange $rest 0 end]"
foreach amsg [channels] { puthelp "PRIVMSG $amsg :$rest" }
return 0
}

proc dns:res {nick uhost hand chan text} {
 if {$text == ""} {
            puthelp "privmsg $chan :Syntax: [string trim $dnshost(cmdchar)]dns <host or ip>"
        } else {
                set hostip [split $text]
                dnslookup $hostip resolve_rep $chan $hostip
        }
}

proc dns:nick {nick uhost hand chan arg} {
global dns_chan dns_bynick dnshost
 if {$arg == ""} {
 puthelp "privmsg $chan :Syntax: [string trim $dnshost(cmdchar)]dnsnick <nick>"
        } else {
set dns_chan "$chan"
set dns_bynick "oui"
putserv "WHOIS [lindex $arg 0]"
        }
}

proc resolve_rep {ip host status chan hostip} {
        if {!$status} {
                puthelp "privmsg $chan :Unable to resolve $hostip ."
        } elseif {[regexp -nocase -- $ip $hostip]} {
                puthelp "privmsg $chan :$ip resolve $host"
        } else {
                puthelp "privmsg $chan :$host resolve $ip"
        }
}

putlog "Dns Resolver 1.0 by terroris Loaded"


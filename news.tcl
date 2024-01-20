#./twlc news retreiving tcl coded by Defcon7, idea of supergate :)
#This small tcl script is protected by copyright, because this is only intended to use with ./twlc backend.
#Since twlc.net has the same backend.php of all the websites that run phpnuke we will release a public and GPL licensed version of this tcl soon.

#Default maximum number of news, you can set this to "" if u dont want a maximum number, 
#you also can specify (and ovveride to this) the number of wanted news with !trigger numberofnews ex: !news 10
set defnews "5"


#Trigger for requesting news (default !news)
set nwtrig !news


bind pub - $nwtrig news_get
set stackable-commands "TOPIC PART WHOIS USERHOST USERIP ISON"

proc news_get { nick uhost hand chan arg} {
		global defnews nwtrig
		set dfnews $defnews
		set nrnews [lindex $arg 0]
                if {![string is integer $nrnews]} {putquick "NOTICE $nick :Usage $nwtrig for default number of news or $nwtrig number for a defined number of news" ; return }
                set chid [socket www.twlc.net 80]
		puts $chid "GET /backend.php\r\n"
		flush $chid
                if {$nrnews != ""} {incr nrnews}
                if {$dfnews != ""} {incr dfnews} else {set dfnews 2000}
                set i 0
                set ln 0
        while {![eof $chid]} {
        set line [gets $chid] 
        if {[string match "*<title>*" $line] || [string match "*<link>*" $line]} {
        set line [string map [list "</channel>" "" "<channel>" "" "\r" "" "<link>" "" "</link>" "" "<title>" "" "</title>" "" "\n" "" "<item>" "" "</item>" "" "<rss>" "" "</rss>" ""] $line ]
                if {[llength $line] >= "1"} {
                lappend buffer $line
              	incr ln
                }
                if {$ln == 1} {set buffer "\002$buffer\002" }
                if {$ln == "2"} { 
        		set buffer [string map [list "\{" "" "\}" "" ] [join $buffer]]
                        incr i
                        if {($i != "1") && ((($nrnews != "") && ($nrnews >= $i)) || (($nrnews == "") && ($dfnews >= $i)))} {
                		putquick "privmsg $nick :$buffer"
                        }
                        
                        set ln 0
                        set buffer ""
                } 
       	}
        }
if { $nrnews != "" } {
	putquick "privmsg $nick :End of requested news" 
} else { 
	putquick "privmsg $nick :End of ./twlc news"  
}
close $chid
}



putlog "Latest news crowler (www.twlc.net) v1.0 loaded (Coded by Defcon7)"

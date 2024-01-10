
#################################################################################
#
# Csc TCL 1.2
#
#Check the status of an existing channel aplication through CService on UnderNet.
#
#	To enable : .chanset #canal +csc | .set +csc (BlackTools)
#
#	Usage : .csc <channel>
#
#Packages required : http, tls
#
#; Originaly wroted by BaRDaHL
#; Fixed SSL issue and tranlated to english by Sebastien
#; Fixed some bugs, added description and modified some things by BLaCkShaDoW
#
##################################################################################

###
#Set here the default trigger char
set csc(default_trigger) "."

##################################################################################

package require http
package require tls

setudef flag csc

bind pub - $csc(default_trigger)csc checkcsc

proc checkcsc {nick host hand chan arg} {
if {![channel get $chan csc]} {
	return 0
}
	set valchan [lindex [split $arg] 0]
if { $valchan == "" } { 
	putserv "PRIVMSG $chan :No channel specified to check."
	return 0
}
	::http::config -useragent "lynx"
	::http::register https 443 [list ::tls::socket -autoservername true]
	set token [::http::geturl "https://cservice.undernet.org/live/check_app.php" -query [::http::formatQuery name $valchan] -timeout 10000]
	set html [http::data $token]
if {[string match "*No applications*" $html]} {
	putserv "PRIVMSG $chan :$valchan: Is not in any kind of registration process, Try again."
	return 0
	}
if {[string match "*DB is currently being maintained*" $html]} {
	putserv "PRIVMSG $chan :$valchan: The CService Database in unavailable At The moment. Please Try again later."
	return 0
}
	upvar #0 $token state
	foreach {name value} $state(meta) {
		if {[regexp -nocase ^location$ $name]} {
			set regurl "https://cservice.undernet.org/live/$value"
			set token [http::geturl $regurl]
			set html [http::data $token]
			set html [split $html "\n"]
			set regobj 0
			set regcomment ""
			foreach line $html {
				if {[string match "*by user :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah reguser blah
				}

				if {[string match "*Posted on :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah regdate blah
				}
				if {[string match "*Current status :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah regstatus blah
					regsub -all {<[^>]*>} $regstatus {} regstatus
				}
				if {[string match "*Decision comment :*" $line]} {
					regexp {(.*)<b>(.*)</b>(.*)} $line match blah regcomment blah
					regsub -all {<[^>]*>} $regcomment {} regcomment2
				}
				if {[string match -nocase "*Description :*" $line]} {
					regexp -nocase {(.*)<b>(.*)</b>(.*)} $line match blah regdesc blah
					if {![info exists regdesc]} {
						regexp -nocase {(.*)<b>(.*)} $line match blah regdesc
					}
					regsub -all {<[^>]*>} $regdesc {} regdesc2
				}
				if {[string match "*Comment :*" $line]} {
					incr regobj 1
				}
				if {![info exists regcomment2]} {
					set regcomment2 "n/a"
				}
			}
		}
	}
	set regstatus2 [string tolower $regstatus]
	if {$regstatus2 == "pending"} {
		set regstatus "\00312$regstatus\003"
	} elseif {$regstatus2 == "incoming"} {
		set regstatus "\00308$regstatus\003"
	} elseif {$regstatus2 == "rejected"} {
		set regstatus "\00304$regstatus\003"
	} elseif {$regstatus2 == "accepted"} {
		set regstatus "\00309$regstatus\003"
	} elseif {$regstatus2 == "ready for review"} {
		set regstatus "\00306$regstatus\003"
	} elseif {$regstatus2 == "cancelled by the applicant"} {
		set regstatus "\00314$regstatus\003"
	}
	putserv "PRIVMSG $chan :\[\00314CService\003\] Status for \002$valchan\002 --> $regstatus" 
	putserv "PRIVMSG $chan :\002Username:\002 $reguser - \002Date:\002 $regdate - \002Objections:\002 $regobj - \002Comments:\002 $regcomment2"
	putserv "PRIVMSG $chan :\002Description:\002 $regdesc"
	putserv "PRIVMSG $chan :\002URL:\002 $regurl"
	return 0
}

##################################################################################


putlog "Csc TCL 1.2 Loaded (Originaly wroted by BaRDaHL)"


bind pub - !dwhois dwhois
proc dwhois {nick host handle chan text} {
set server "isfree.schlundtec.com"
set port 80
set l 14
set i 0
set path "/cgi-bin/isfree.cgi?nodesign=1&domain=[lindex $text 0]"
set sockdw [socket $server $port]
puts $sockdw "GET $path HTTP/1.0"
puts $sockdw "User.Agent:Mozilla"
puts $sockdw "Host: $server"
puts $sockdw ""
flush $sockdw
	while {$i <= $l} {
		gets $sockdw linedw
		putlog $linedw
		if {[string match "*Domain*frei*" $linedw]} {
			putserv "PRIVMSG $chan :[lindex $text 0] is free"
			close $sockdw
			return 0
		}
		if {[string match "*Domain*registriert*" $linedw]} {
			gets $sockdw
			putserv "PRIVMSG $chan :Pemilik: [html [gets $sockdw]] Jalan: [html [gets $sockdw]] Kota: [html [gets $sockdw]] Negara: [html [gets $sockdw]]"
			close $sockdw
			return 0
		}
		incr i
	}
	close $sockdw
}
proc html { text } {
regsub -all "</TD>" $text "" text
regsub -all "</FONT>" $text "" text
regsub -all "	" $text "" text
regsub -all "&uuml;" $text "ü" text
regsub -all "&ouml;" $text "ö" text
regsub -all "&auml;" $text "ä" text
regsub -all "&Uuml;" $text "Ü" text
regsub -all "&Ouml;" $text "Ö" text
regsub -all "&Auml;" $text "Ä" text
regsub -all "&szlig;" $text "ß" text
regsub -all "&quot;" $text "\"" text
regsub -all "<tb>" $text "" text
regsub -all "<font" $text "" text
regsub -all "size=\"2\"" $text "" text
regsub -all "face=\"Verdana,Arial,Helvetica,Geneva\">" $text "" text
regsub -all "<br>" $text "" text
regsub -all "&nbsp;" $text "" text
regsub -all "</font>" $text "" text
regsub -all "<td>" $text "" text
regsub -all "</td>" $text "" text
regsub -all "<b>" $text "" text
regsub -all "</b>" $text "" text
regsub -all "</pre>" $text "" text
return $text
}

putlog "dwhois 1.0 by terroris Loaded"

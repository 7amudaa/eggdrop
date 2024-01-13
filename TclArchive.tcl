#######################################################################################################
##                          _   _   _   _   _   _   _   _   _   _   _   _   _   _                    ##
##                         / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \                   ##
##                        ( T | C | L | S | C | R | I | P | T | S | . | N | E | T )                  ##
##                         \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/                   ##
##                                                                                                   ##
##                                      ® BLaCkShaDoW Production ®                                   ##
##                                                                                                   ##
##                                              PRESENTS                                             ##
##                                                                                                   ##
#########################################  TCLARCHIVE SEARCH TCL   ####################################
##                                                                                                   ##
##  This script searches on TclArchive.org website and pulls informations matching title, author,    ##
##  description or download link.                                                                    ##
##                                                                                                   ##
##  Tested on Eggdrop v1.8.2 (Debian Linux 3.16.0-4-amd64) Tcl version: 8.6.6                        ##
##                                                                                                   ##
#######################################################################################################
##                                                                                                   ##
##  Installation:                                                                                    ##
##     ++ http package is REQUIRED for this script to work.                                          ##
##     ++ Edit the TclArchive.tcl script and place it into your /scripts directory,                  ##
##     ++ add "source scripts/TclArchive.tcl" to your eggdrop config and rehash the bot.             ##
##                                                                                                   ##
#######################################################################################################
##                                                                                                   ##
##  Official links:                                                                                  ##
##   E-mail      : BLaCkShaDoW[at]tclscripts.net                                                     ##
##   Bugs report : http://www.tclscripts.net                                                         ##
##   GitHub page : https://github.com/tclscripts/                                                    ##
##   Online help : irc://irc.undernet.org/tcl-help                                                   ##
##                 #TCL-HELP / UnderNet                                                              ##
##                 You can ask in english or romanian                                                ##
##                                                                                                   ##
#######################################################################################################
##                                                                                                   ##
##                           You want a customised TCL Script for your eggdrop?                      ##
##                                Easy-peasy, just tell me what you need!                            ##
##                I can create almost anything in TCL based on your ideas and donations.             ##
##                  Email blackshadow@tclscripts.net or info@tclscripts.net with your                ##
##                    request informations and I'll contact you as soon as possible.                 ##
##                                                                                                   ##
#######################################################################################################
##                                                                                                   ##
##  To activate: .chanset +tclarchive | from BlackTools: .set #channel +tclarchive                   ##
##                                                                                                   ##
##  !atcl - view latest 10 scripts added                                                             ##
##                                                                                                   ##
##  !atcl [search keyword] [-p] <nr> - search by a keyword with the posibility to select page        ##
##                                                                                                   ##
##  !atcl -top [-p] <nr> - view the tcl's sorted by download number, with the posibility to select page
##                                                                                                   ##
##  To view a entire page (50 tcl's) just use the same command again and again and the eggdrop will  ##
##  show you every the number of entries you setup in the tclarchive(max_entries) variable.          ##
##                                                                                                   ##
#######################################################################################################

#######################################################################################################
##                                    CONFIGURATION FOR TclArchive.TCL                               ##
#######################################################################################################

###
#Here you set the flags needed to run the track command
set tclarchive(use_flags) "nm|oMmN"

###
#set here the details for the tcl line to contain
#you can select from : %tcl_name%, %tcl_version%, %download_link%, %date%, %author%
#%download_number%, %description_file%, %description%, %category%
#You can setup your line in what matter you like :P
set tclarchive(tcl_line) "\[TCL\] \002%tcl_name%\002 %tcl_version% ; Author: %author% ; Download link: %download_link% ; Upload date: %date% ; Description: %description%"

###
#Set here the entries to show foreach command (to list tcl's from a page)
set tclarchive(max_entries) "3"

###
# Channel flag
setudef flag tclarchive

###########################################################################################
###              DO NOT MODIFY HERE UNLESS YOU KNOW WHAT YOU DOING                      ###
###########################################################################################

####
# Bindings
bind pub $tclarchive(use_flags) !atcl tclarchive:get

###
proc tclarchive:get {nick host hand chan arg} {
	global tclarchive
if {![channel get $chan tclarchive]} {
	return
}
	set search_it [lrange [split $arg] 0 end]
	set get_page [wsplit $search_it "-p"]
	set page [concat [lindex $get_page 1]]
	set search [concat [lindex $get_page 0]]
if {$search == ""} {
	set return [tclarchive:read "new" "" ""]
	set get [tclarchive:getinfo $return]
	tclarchive:say $nick $host $chan $get 0 "" $page
} elseif {[string match -nocase $search "-top"]} {
if {$page == ""} {
	set return [tclarchive:read "top" "" ""]
	} else {
	set return [tclarchive:read "top" "" $page]
	}
	set get [tclarchive:getinfo $return]
	tclarchive:say $nick $host $chan $get 2 $search_it $page
} else {
	set join_search [join $search "+"]
if {$page == ""} {
	set return [tclarchive:read "search" $join_search ""]
	} else {
	set return [tclarchive:read "search" $join_search $page]
	}
	set get [tclarchive:getinfo $return]
if {$page == ""} { set page 1 }
	tclarchive:say $nick $host $chan $get 1 $search_it $page
	}
}

###
proc tclarchive:say {nick host chan data type text page} {
	global tclarchive
	set nr_pag 1
	set remain 0
	set llength [llength $data]
	set found [lindex $data [expr $llength - 1]]
if {$found == "-1"} {
	putserv "PRIVMSG $chan :\[TCL\] No matches found for \002$text\002"
	return
}
	set data [lrange $data 0 end-1]
	set get_pag [expr $found / 50]
	set nr_pag [expr $get_pag + 1]

if {$page > $nr_pag || $page == ""} { set page 1 }
foreach p [split $page ""] {
if {![regexp {^[0-9]} $p]} { set page 1 } 
}

if {![info exists tclarchive(show:$host:$chan:searched)]} {
if {$type == "1"} {
	putserv "PRIVMSG $chan :\[TCL\] Found \002$found\002 matches ($page/$nr_pag pages ; use -p \[nr\] to view)"
} elseif {$type == "0"} {
	putserv "PRIVMSG $chan :\[TCL\] Latest \00210\002 scripts added added in the last 180 days are"
} elseif {$type == "2"} {
	putserv "PRIVMSG $chan :\[TCL\] Found \002$found\002 matches \[sorted by download number\] ($page/$nr_pag pages ; use -p \[nr\] to view)"
}
	set tclarchive(show:$host:$chan:searched) $text
	set tclarchive(show:$host:$chan:count) 0
		} else {
if {[string tolower $tclarchive(show:$host:$chan:searched)] != [string tolower $text]} {
if {$type == "1"} {
	putserv "PRIVMSG $chan :\[TCL\] Found \002$found\002 matches ($page/$nr_pag pages ; use -p \[nr\] to view)"
} elseif {$type == "0"} {
	putserv "PRIVMSG $chan :\[TCL\] Latest \00210\002 scripts added added in the last 180 days are"
} elseif {$type == "2"} {
	putserv "PRIVMSG $chan :\[TCL\] Found \002$found\002 matches \[sorted by download number\] ($page/$nr_pag pages ; use -p \[nr\] to view)"
}
	set tclarchive(show:$host:$chan:count) 0
	set tclarchive(show:$host:$chan:searched) $text
	}
}
	set tclarchive(show:$host:$chan:ltext) [llength $data]
	set difference [expr $tclarchive(show:$host:$chan:ltext) - $tclarchive(show:$host:$chan:count)]
if {$difference >= $tclarchive(max_entries)} {
for {set i $tclarchive(show:$host:$chan:count)} { $i < [expr $tclarchive(show:$host:$chan:count) + $tclarchive(max_entries)] } { incr i } {
	set current_text [lindex $data $i]
	set download_link "http://tclarchive.org[lindex $current_text 3]"	
if {[llength [lindex $current_text 8]] > 15} {
	set desc "[lrange [lindex $current_text 8] 0 15] ..."
} else {
	set desc [lindex $current_text 8]
}	
	set list [list [lindex $current_text 0] [lindex $current_text 1] [lindex $current_text 2] $download_link $[lindex $current_text 4] [lindex $current_text 5] [lindex $current_text 6] [lindex $current_text 7] $desc] 
	tclarchive:show $nick $chan $list
	}
	set tclarchive(show:$host:$chan:count) [expr $tclarchive(show:$host:$chan:count) + $tclarchive(max_entries)]
	set remain [expr $difference - $tclarchive(max_entries)]
if {$remain > 0 } {
if {$text == ""} {
	putserv "PRIVMSG $chan :\[TCL\] \002$remain\002 tcl's left to show, type \002!atcl\002 again"
} else {
	putserv "PRIVMSG $chan :\[TCL\] \002$remain\002 tcl's left to show, type \002!atcl $text\002 again"
	}
}
foreach tmr [utimers] {
if {[string match -nocase "*tclarchive:say:unset $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
		}
	}
	utimer 30 [list tclarchive:say:unset $host $chan]
} else {
for {set i $tclarchive(show:$host:$chan:count)} { $i < [expr $tclarchive(show:$host:$chan:count) + $difference] } { incr i } {
	set current_text [lindex $data $i]
if {[lindex $current_text 1] == "-"} { set tcl_version "" } { set tcl_version [lindex $current_text 1] }
	set download_link "http://tclarchive.org[lindex $current_text 3]"
if {[llength [lindex $current_text 8]] > 15} {
	set desc "[lrange [lindex $current_text 8] 0 15] ..."
} else {
	set desc [lindex $current_text 8]
}
	set list [list [lindex $current_text 0] [lindex $current_text 1] [lindex $current_text 2] $download_link $[lindex $current_text 4] [lindex $current_text 5] [lindex $current_text 6] [lindex $current_text 7] $desc] 
	tclarchive:show $nick $chan $list
			}
	tclarchive:say:unset $host $chan
	return		
	}
}

proc tclarchive:show {nick chan list} {
	global tclarchive
	set replace(%tcl_name%) [lindex $list 0]
	set replace(%tcl_version%) [lindex $list 1]
	set replace(%category%) [lindex $list 2]
	set replace(%download_link%) [lindex $list 3]
	set replace(%description_file%) [lindex $list 4]
	set replace(%download_number%) [lindex $list 5]
	set replace(%date%) [lindex $list 6]
	set replace(%author%) [lindex $list 7]
	set replace(%description%) [lindex $list 8]
	set line [string map [array get replace] $tclarchive(tcl_line)]
	putserv "PRIVMSG $chan :$line"
}

###
# Credits
set tclarchive(projectName) "TclArchive Search"
set tclarchive(author) "BLaCkShaDoW"
set tclarchive(website) "wWw.TCLScriptS.NeT"
set tclarchive(email) "BLaCkShaDoW@TCLScriptS.NeT"
set tclarchive(version) "v1.0"

###
proc tclarchive:say:unset {host chan} {
	global tclarchive
if {[info exists tclarchive(show:$host:$chan:count)]} {
	unset tclarchive(show:$host:$chan:count)
}		
if {[info exists tclarchive(show:$host:$chan:searched)]} {
	unset tclarchive(show:$host:$chan:searched)
	}
if {[info exists tclarchive(show:$host:$chan:ltext)]} {
	unset tclarchive(show:$host:$chan:ltext)
	}
}

###
proc tclarchive:getinfo {data} {
	set inc 0
	set title ""
	set downloads ""
	set category ""
	set date ""
	set bywho ""
	set desc ""
	set text ""
	set notfound 0
	set found_match 0
foreach line $data {
	set has_category 0
	set inc [expr $inc + 1]
if {[string match -nocase "*Found * match*" $line]} {
	set found_match [lindex [tclarchive:filter "$line"] 1]
}
if {[string match -nocase "*No matches were found*" $line]} {
	set notfound 1
}
if {[string match -nocase "* <tr class=\"tbody odd\">*" $line] || [string match -nocase "* <tr class=\"tbody even\">*" $line]} {
	set download_link [tclarchive:filter [lindex $data $inc]]
	set title [tclarchive:filter [lindex $data [expr $inc + 1]]]
	set split_title [split $title ">"]
	set title [lindex $split_title 1]
	set category [lindex $data [expr $inc + 2]]
if {[string match -nocase "*<small>*" $category]} {
	set has_category 1
	set category [tclarchive:filter $category]
} else {
	set category "-"
}
if {$has_category  == "1"} {
	set version [tclarchive:filter [lindex $data [expr $inc + 5]]]
	set downloads [concat [tclarchive:filter [lindex $split_title 0]]]
	set date [tclarchive:filter [lindex $data [expr $inc + 8]]]
	set bywho [tclarchive:filter [lindex $data [expr $inc + 11]]]
	set desc [tclarchive:filter [lindex $data [expr $inc + 15]]]
	set desc_file [tclarchive:filter [lindex $data [expr $inc + 17]]]
} else {
	set version [tclarchive:filter [lindex $data [expr $inc + 4]]]
	set downloads [concat [tclarchive:filter [lindex $split_title 0]]]
	set date [tclarchive:filter [lindex $data [expr $inc + 7]]]
	set bywho [tclarchive:filter [lindex $data [expr $inc + 10]]]
	set desc [tclarchive:filter [lindex $data [expr $inc + 14]]]
	set desc_file [tclarchive:filter [lindex $data [expr $inc + 16]]]
}
if {[string match -nocase "*</td>*" $desc_file]} {
	set desc_file "-"
}
	lappend text [list $title $version $category $download_link $desc_file $downloads $date $bywho $desc]
		}
	}
if {$notfound == "1"} {
	lappend text [list "-1"]
	} else {
	lappend text [list $found_match]
	}
	return $text
}

###
proc tclarchive:read {type search page} {
	global black
	set getlink ""
switch $type {
	new {
	set getlink "http://tclarchive.org/search.php?New"
		}
	search {
if {$page == ""} { set page 1 }
	set getlink "http://tclarchive.org/search.php?str=$search&pg=$page"
		}
	top {
if {$page != ""} {
	set getlink "http://tclarchive.org/search.php?cate=top&pg=$page"
} else {
	set getlink "http://tclarchive.org/search.php?Top"
			}
		}
	}
	set ipq [http::config -useragent "lynx"]
	set ipq [http::geturl $getlink -timeout 50000]
	set return [http::data $ipq]
	::http::cleanup $ipq
	set output [split $return "\n"]
	return $output
}

###
proc tclarchive:filter {text} {
	set text [string map {
			 "  " ""
			 "<td scope=\"row\"><a href=\"" ""
		     "\">" ""
			 "<span title=\"" ""
			 "downloads\"" ""
			 "</span>" ""
			 "<span>" ""
			 "<span class=\"more\">" ""
			 "<span class=\"" ""
			 "<mark>" ""
			 "</mark>" ""
			 "<p>" ""
			 "\" tabindex=\"-1" ""
			 "<small>" "" 
			 "</small>" ""
			 "&amp;" "&"
			 "<span><a href=\"" ""
			 "\" title=\"View script description file\">" ""
			 "<a href=\"" ""
			 "&quot;" "\""
			 "&#039;" "'"
			 "&lt;" "<"
			 "&gt;" ">"					} $text]
	return $text
}

###
#http://wiki.tcl.tk/989
proc wsplit {string sep} {
    set first [string first $sep $string]
    if {$first == -1} {
        return [list $string]
    } else {
        set l [string length $sep]
        set left [string range $string 0 [expr {$first-1}]]
        set right [string range $string [expr {$first+$l}] end]
        return [concat [list $left] [wsplit $right $sep]]
    }
}

putlog "\002$tclarchive(projectName) $tclarchive(version)\002 coded by\002 $tclarchive(author)\002 ($tclarchive(website)): Loaded & initialized.."

#######################
#######################################################################################################
###                  *** END OF TclArchive TCL ***                                                  ###
#######################################################################################################

 ##########################################################################################
## BlackRSS 1.0  (04/05/2020)                                               ##
##                                                                                 ##
##                                 Copyright 2008 - 2020 @ http://sabo.free.bg/tcls/       ##
##                _   _   _   _   _   _   _   _   _   _   _   _   _   _                ##
##           / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \                ##
##              ( T | C | L | S | C | R | I | P | T | S | . | N | E | T )             ##
##           \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/               ##
##                                                                                 ##
##                          ® Krasi Production ®                                     ##
##                                                                                  ##
##                                   PRESENTS                                       ##
##                                   ® ##
####################################   BlackRSS TCL   ####################################
##                                       ##
##  DESCRIPTION:                                  ##
##  Gets news from RSS sites added via IRC. Now featuring a preferential setting      ##
##  that let's the user define his keywords to get only the news that contains them.       ##
##  Every chan can have its own list of RSS feeds to check.               ##
##                                          ##
##  Tested on Eggdrop v1.8.4 (Debian Linux) Tcl version: 8.6.6                      ##
##                                       ##
##########################################################################################
##                                            ##
##  INSTALLATION:                                       ##
##  ++ http, tdom & tls packages are REQUIRED for this script to work.              ##
##  ++ Edit BlackRSS.tcl script & place it into your /scripts directory.         ##
##  ++ add "source scripts/BlackRSS.tcl" to your eggdrop.conf & rehash.           ##
##                                            ##
##                                    ##
##########################################################################################
##                                    ##
##Commands for RSS                              ##
##                                    ##
## !rss - shows the ID's and the commands for the RSS added               ##
##                                    ##
## !rss add <rss cmd> <link> <name> [num=X time=X enc=X word=X,Y,Z]            ##
##                                    ##
## Options (if not specified the standard values are set bellow):            ##
## num=X -> define the number of new rss news to get ; ex: num=5            ##
##                                    ##
## time=X -> define the time in minutes for the bot to check for new news ; ex: time=3     ##
##                                    ##
## enc=X -> define the 'encoding' if the news aren't looking so great (like utf-8)      ##
##                                    ##
## word=X,Y,Z -> define keywords for the rss news (only the news that contain one of       ##
##               the words specified in the title or desc will be shown)         ##
##       ex: word=coronavirus,pandemic,covid                  ##
##                                    ##
##--- You can specify one, all or none of the options shown               ##
##                                    ##
## !rss list -> lists each RSS news added with their details (id,cmd,link, etc.)      ##
##                                    ##   
## !rss del <id> (removes an added RSS, the ID can be taken from !rss list or !rss)        ##
##                                    ##   
## !rss check <link> (checks a RSS link)                     ##
##                                    ##
## !rss help - shows the help :P                        ##   
##                                    ##
##                                    ##                        
##########################################################################################
##                                    ##
##        OFFICIAL LINKS:                                                            ##
##         E-mail      : kcdenkov@gmail.com                                           ##
##         Bugs report : http://http://sabo.free.bg/tcls/                            ##
##         GitHub page : http://freeunibg.eu/                         ##
##         Online help : irc.sabo.bg                                                  ##
##                       #irc.sabo.bg / FreeUniBG                                      ##
##              You can ask in english or romanian                                ##
##                                      ##
##        paypal Krasi@FreeUniBG                                                        ##
##                                      ##
#########################################################################################
##                                      ##
##             You want a customised TCL Script for your eggdrop?                        ##
##                   Easy-peasy, just tell me what you need!                          ##
##     I can create almost anything in TCL based on your ideas and donations.        ##
##         Email blackshadow@tclscripts.net or info@tclscripts.net with your          ##
##          request informations and I'll contact you as soon as possible.              ##
##                                     ##
#########################################################################################
##                                               ##
##        PERSONAL AND NON-COMMERCIAL USE LIMITATION.                               ##
##                                                                                 ##
##        This program is provided on an "as is" and "as available" basis,                 ##
##        with ABSOLUTELY NO WARRANTY. Use it at your own risk.                        ##
##                                                                                 ##
##       Use this code for personal and NON-COMMERCIAL purposes ONLY.                 ##
##                                                                                 ##
##        Unless otherwise specified, YOU SHALL NOT copy, reproduce, sublicense,          ##
##        distribute, disclose, create derivatives, in any way ANY PART OF              ##
##        THIS CONTENT, nor sell or offer it for sale.                                  ##
##                                                                                  ##
##        You will NOT take and/or use any screenshots of this source code for            ##
##        any purpose without the express written consent or knowledge of author.         ##
##                                                                                ##
##       You may NOT alter or remove any trademark, copyright or other notice            ##
##        from this source code.                                                          ##
##                                                                                  ##
##                    Copyright 2008 - 2020 @ http://sabo.free.bg/tcls/           ##
##                                                                                  ##
#########################################################################################

##
#Set RSS output line
#  %rssname% - name of the RSS
#  %title% - news title
#  %link% - news link
#  %date% - news date [some rss feeds dont have date]
##

set rss(rss_output) "\[\002%rssname%\002\] \002Title\002: %title% --- \002Link\002: %link% --- \002Update\002: %date%"

##
#Default char for RSS command

set rss(rss_char) "!"


##
#Flags for using RSS feeds commands added ( -|- for everyone )

set rss(rss_show_flags) "nm|o"

##
#Flags needed to add/list/remove RSS feeds

set rss(rss_add_flags) "nm|MN"

##
#Set default time to check for now RSS (minutes)
set rss(default_check_time) "5"


##
#Set default number of new RSS news to get
set rss(news_number) "3"

##
#Use is.gd to shrink links ? (1 - yes ; 0 - no )
set rss(tiny_link) "1"

########################################################################################

package require tls
package require http
package require tdom

bind pub - $rss(rss_char)rss rss:cmd
bind pubm - * rss:cmd:act
setudef flag rss

set rss(directory) "scripts/RSS"
set rss(filelist) "$rss(directory)/rss_list.txt"


if {![file isdirectory $rss(directory)]} {
   file mkdir $rss(directory)
}

if {![file exists $rss(filelist)]} {
   set file [open $rss(filelist) w]
   close $file
}

if {![info exists rss(timer_start)]} {
   timer 1 rss:timer
   set rss(timer_start) 1
}

###
proc rss:cmd:act {nick host hand chan arg} {
   global rss
if {![channel get $chan rss]} {
   return
}

if {[matchattr $hand $rss(rss_show_flags) $chan]} {
if {[info exists rss(cmd_show:$chan)]} {
   putserv "NOTICE $nick :Let me finish showing the RSS news requested."
   return
}
if {![info exists rss(rss_list)]} {
   set get_list [rss:get_list]
   set rss(rss_list) $get_list
}
   set read_id ""
   set read_chan ""
   set read_link ""
   set read_time ""
   set read_num ""
   set read_enc ""
   set read_name ""
   set rss_word ""
   set news ""
   set noinfo 0
   set word_pattern ""
   set counter 0
   set cmd [lindex [split $arg] 0]
   set data [split $rss(rss_list) "\n"]
   set search [lsearch -nocase $rss(rss_list) $cmd]
if {$search > -1} {
   foreach line $data {
   set read_cmd [lindex [split $line] 2]
   set read_chan [lindex [split $line] 1]
if {[string equal -nocase $cmd $read_cmd] && [string equal -nocase $read_chan $chan]} {
   set read_id [lindex [split $line] 0]
   set read_link [lindex [split $line] 3]
   set read_num [lindex [split $line] 5]
   set read_enc [lindex [split $line] 6]
   set read_name [lrange [split $line] 7 end]
   set split_name [rss:wsplit $read_name "%word%"]
   set rss_word [lindex $split_name 1]
   set read_name [concat [lindex $split_name 0]]
   break
   }
}
   set current_data [rss:data $read_link 0]
if {[llength [split $current_data]] <= 2} {
   if {$current_data != "ok" || $current_data == "2" || $current_data == "0" || $current_data == "3"} {
   set noinfo 1
   }
}

if {$noinfo == 1} {
   putserv "NOTICE $nick :No news for \002$read_name\002"
   return
}
   set items [rss:items $current_data]
if {$items == ""} {
   putserv "NOTICE $nick :No news for \002$read_name\002"
   return
}
   set split_word [rss:wsplit $rss_word ","]
   foreach w $split_word {
if {$w != ""} {
   lappend word_pattern $w
   }
}
   set word_pattern [join $word_pattern "|"]
if {$rss_word == ""} {
foreach item $items {
   lappend news $item
   incr counter
if {$counter == $read_num} {
   break
            }
         }
   } else {
foreach item $items {
   set read_title [lindex $item 0]
   set read_desc [lindex $item 1]
if {[regexp -nocase $word_pattern $read_title] || [regexp -nocase $word_pattern $read_desc]} {
   lappend news $item
   incr counter
if {$counter == $read_num} {
   break
                  }
               }
            }   
         }         
      } else { return }
      
if {$news != ""} {
   set rss(cmd_show:$chan) 1
   rss:cmd:act_now $chan $news $read_name $read_enc 0
      } else {
   putserv "NOTICE $nick :No news for \002$read_name\002"   
      }
   }
}


###
proc rss:cmd:act_now {chan data rssname enc num} {
   global rss
   set line [lindex $data $num]
   set eth [rss:special_text "Ð"]
if {$enc != "-"} {
   set title [encoding convertfrom $enc [rss:special_text [lindex $line 0]]]
   set desc [encoding convertfrom $enc [rss:special_text [lindex $line 1]]]
} else {
   set title [rss:special_text [lindex $line 0]]
   set desc [rss:special_text [lindex $line 1]]
if {[regexp $eth $title]} {
   set title [encoding convertfrom "utf-8" [rss:special_text [lindex $line 0]]]
}
if {[regexp $eth $desc]} {
   set desc [encoding convertfrom "utf-8" [rss:special_text [lindex $line 1]]]
   }
}
if {$rss(tiny_link) == "1"} {
   set link [b0:short [lindex $line 2]]
} else {
   set link [lindex $line 2]
}
   set pubdate [lindex $line 3]
   
   set replace(%rssname%) $rssname
   set replace(%title%) $title
   set replace(%link%) $link
   set replace(%date%) $pubdate
   set reply [string map [array get replace] $rss(rss_output)]
   puthelp "PRIVMSG $chan :$reply"
   set inc [expr $num + 1]
if {[lindex $data $inc] != ""} {
   utimer 1 [list rss:cmd:act_now $chan $data $rssname $enc $inc]
   } else {
   unset rss(cmd_show:$chan)
   }
}


###
proc rss:timer {} {
   global rss
   set check_time_now ""
if {![info exists rss(rss_list)]} {
   set get_list [rss:get_list]
if {$get_list == ""} {
   timer 1 rss:timer
   return
   } else {
   set rss(rss_list) $get_list
   }
}
   set data [split $rss(rss_list) "\n"]
foreach line $data {
   set id [lindex $line 0]
   set check_time [lindex $line 4]
if {![info exists rss(check:$id:time)]} {
   set rss(check:$id:time) 0
      }
   incr rss(check:$id:time)
if {$rss(check:$id:time) == $check_time} {
   lappend check_time_now $line
   unset rss(check:$id:time)
      } elseif {$rss(check:$id:time) > $check_time} {
   unset rss(check:$id:time)
      }
   }
if {$check_time_now != ""} {
   rss:timer:check $check_time_now 0
   } else {
   timer 1 rss:timer
   }
}


###
proc rss:timer:check {data num} {
   global rss botnick
   set line [lindex $data $num]
   set id [lindex $line 0]
   set filename "$rss(directory)/$id"
   set chan [lindex $line 1]
   set url [lindex $line 3]
   set rss_num [lindex $line 5]
   set rss_enc [lindex $line 6]
   set rss_name [lrange $line 7 end]
   set split_name [rss:wsplit $rss_name "%word%"]
   set rss_word [lindex $split_name 1]
   set rss_name [concat [lindex $split_name 0]]
   set skip 0
   set new_news ""
   set old_news ""
   set word_pattern ""
   set news_counter 0
   set split_word [rss:wsplit $rss_word ","]
   set eth [rss:special_text "Ð"]
foreach w $split_word {
if {$w != ""} {
   lappend word_pattern $w
   }
}
   set word_pattern [join $word_pattern "|"]
   set current_data [rss:data $url 0]
if {[llength [split $current_data]] <= 2} {
   if {$current_data != "ok" || $current_data == "2" || $current_data == "0" || $current_data == "3"} {
   set skip 1
   }
}

if {$skip == 1} {
   set inc [expr $num + 1]
if {[lindex $data $inc] != ""} {
   utimer 5 [list rss:timer:check $data $inc]
   return
      } else {
   timer 1 rss:timer
   return   
      }
   }
   set items [rss:items $current_data]
if {$items == ""} {
      set inc [expr $num + 1]
if {[lindex $data $inc] != ""} {
   utimer 5 [list rss:timer:check $data $inc]
   return
      } else {
   timer 1 rss:timer
   return   
   }
   return
}
   
if {![file exists $filename]} {
   set file [open $filename w]
   close $file
}
   set file [open $filename r]
   set read [read -nonewline $file]
   close $file
   set split_read [split $read "\n"]
if {$rss_word != ""} {
foreach item $items {
   set read_title [lindex $item 0]
   set read_desc [lindex $item 1]
if {[regexp -nocase $word_pattern $read_title] || [regexp -nocase $word_pattern $read_desc]} {
   incr news_counter
   set link [lindex $item 2]
if {[lsearch -nocase $read $link] < 0} {
   lappend new_news $item
   } else {
   lappend old_news $item   
   }
}
if {$news_counter == $rss_num} {
   break
      }
   }
} else {
foreach item $items {
   incr news_counter
   set link [lindex $item 2]
if {[lsearch -nocase $read $link] < 0} {
   lappend new_news $item   
   } else {
   lappend old_news $item   
}
if {$news_counter == $rss_num} {
   break
      }
   }
}
if {$new_news != ""} {
   set file [open $filename w]
foreach line $new_news {
if {$rss_enc != "-"} {
   set title [encoding convertfrom $rss_enc [rss:special_text [lindex $line 0]]]
   set desc [encoding convertfrom $rss_enc [rss:special_text [lindex $line 1]]]
} else {
   set title [rss:special_text [lindex $line 0]]
   set desc [rss:special_text [lindex $line 1]]
if {[regexp $eth $title]} {
   set title [encoding convertfrom "utf-8" [rss:special_text [lindex $line 0]]]
   }
if {[regexp $eth $desc]} {
   set desc [encoding convertfrom "utf-8" [rss:special_text [lindex $line 1]]]
   }   
}
if {$rss(tiny_link) == "1"} {
   set link [b0:short [lindex $line 2]]
} else {
   set link [lindex $line 2]
}
   set pubdate [lindex $line 3]
if {[onchan $botnick $chan]} {
   set replace(%rssname%) $rss_name
   set replace(%title%) $title
   set replace(%link%) $link
   set replace(%date%) $pubdate
   set reply [string map [array get replace] $rss(rss_output)]
   puthelp "PRIVMSG $chan :$reply"
         }
   puts $file [lindex $line 2]
      }
   close $file
if {[llength $new_news] < $rss_num} {
   set dif [expr [llength $new_news] - $rss_num]
if {$old_news != ""} {
   set cc 0
   set file [open $filename a]
foreach line $old_news {
   incr cc
   set link [lindex $line 2]
   puts $file [lindex $line 2]
if {$cc == $dif} { break }
         }         
   close $file
      }
   }
}
   set inc [expr $num + 1]
if {[lindex $data $inc] != ""} {
   utimer 5 [list rss:timer:check $data $inc]
   return
      } else {
   timer 1 rss:timer
   return   
   }
}


###
proc rss:special_text {string} {
    set map {}
   set string [string map {";" ""} $string]
    foreach {entity number} [regexp -all -inline {&#(\d+)} $string] {
        lappend map $entity [format \\u%04x [scan $number %d]]
    }
    set string [string map [subst -nocomm -novar $map] $string]
   return $string
}

###
proc rss:filter {data} {
   global rss
   set text [string map {   
   "&" "&"
   "&apos;" "'"
   ">" ">"
   "<" "<"
   " " ""
       } $data]
   return $text
}


###
proc rss:items {data} {
   global rss
   set check_date [rss:check_date $data]
   set check_dom [catch {set doc [dom parse $data]} error]
if {$check_dom == 1} {
   return ""
}
   set root [$doc documentElement]
   set items ""
   set pattern {<.*?>}
   set nodeList [$root selectNodes /rss/channel/item]
foreach node $nodeList {
   set title [[$node selectNodes "title"] text]
if {[$node selectNodes "description"] != ""} {
   set description [[$node selectNodes "description"] text]
} else {
   set description "-"
}
   set link [[$node selectNodes "link"] text]
switch $check_date {
   1 {
   set pubdate [[$node selectNodes "pubDate"] text]
   }
   2 {
   set pubdate [[$node selectNodes "dc:date"] text]
   }
   0 {
   set pubdate "-"
   }
}
     regsub -all $pattern $description "" description
     regsub -all $pattern $title "" title
     set description [join [rss:filter [split $description]]]
     set title [join [rss:filter [split $title]]]
     lappend items [list $title $description $link $pubdate]
   }
   return $items
}

###
proc rss:check_date {data} {
   global rss
   set find_date [regexp {<pubDate>(.*)</pubDate>} $data]
if {$find_date == 0} {
   set find_date [regexp {<dc:date>(.*)</dc:date>} $data]
} else {
   return 1
}
if {$find_date == 0} {
   return 0
   } else {
   return 2
   }
}

###
proc rss:data {url type} {
   global rss
   http::register https 443 [list ::tls::socket -autoservername true]
   set ipq [http::config -useragent "lynx"]
   set check_http [catch {set ipq [::http::geturl $url -timeout 10000]}]
if {$check_http == "1"} {
   return 2
}
   set status [::http::status $ipq]
if {$status != "ok"} {
   ::http::cleanup $ipq
   return $status
   }
   set data [http::data $ipq]
   ::http::cleanup $ipq
if {$type == "0"} {
   return $data
} else {
   set check_xml [rss:items $data]
if {$check_xml == "0"} {
      return 3
      }
   return 1
   }
}

###
proc rss:entry_exists {link name cmd chan} {
   global rss
   set file [open $rss(filelist) r]
   set read [read -nonewline $file]
   close $file
if {$read == ""} {
   return 0
   }
   set data [split $read "\n"]
foreach line $data {
   set read_channel [lindex [split $line] 1]
   set read_cmd [lindex [split $line] 2]
   set read_link [lindex [split $line] 3]
   set read_name [lindex [split $line] 4]
if {[string equal -nocase $read_channel $chan]} {
if {[string equal -nocase $read_cmd $cmd]} {
   return 1
} elseif {[string equal -nocase $read_link $link]} {   
   return 2
} elseif {[string equal -nocase $read_name $name]} {   
   return 3               }
      }
   return 0
   }
}

###
proc rss:lastid {chan} {
   global rss
   set file [open $rss(filelist) r]
   set size [file size $rss(filelist)]
   set data [split [read $file $size] \n]
   close $file
   set list [lsearch -all -inline -nocase $data "* $chan * * *"]
if {$list != ""} {
   set sort [lsort -integer -decreasing -index 0 $list]
   return [lindex [lindex $sort 0] 0]
   } else {
   return 0
   }
}


###
proc rss:link_byid {id chan} {
   global rss
   set file [open $rss(filelist) r]
   set read [read -nonewline $file]
   close $file
   set link ""
   set data [split $read "\n"]
foreach line $data {
   set read_id [lindex [split $line] 0]
   set read_channel [lindex [split $line] 1]
if {[string equal -nocase $chan $read_channel] && [string equal -nocase $id $read_id]} {
   set link [lindex [split $line] 3]
   break
      }
   }
   return $link
}

###
proc rss:valid_id {id chan} {
   global rss
   set file [open $rss(filelist) r]
   set size [file size $rss(filelist)]
   set data [split [read $file $size] \n]
   close $file
   set list [lsearch -all -inline -nocase $data "$id $chan * * *"]
if {$list != ""} {
   return 1
   } else {
   return 0
   }
}


###
proc rss:get_list {} {
   global rss
   set file [open $rss(filelist) r]
   set read [read -nonewline $file]
   close $file
   return $read
}

proc rss:list {nick chan} {
   global rss
   set found 0
   set file [open $rss(filelist) r]
   set read [read -nonewline $file]
   close $file
if {$read == ""} {
   return 0
}
   set data [split $read "\n"]
foreach line $data {
   set read_channel [lindex [split $line] 1]
if {[string equal -nocase $chan $read_channel]} {
   set found 1
   set read_id [lindex [split $line] 0]
   set link [lindex [split $line] 3]
   set rss_time [lindex [split $line] 4]
   set rss_num [lindex [split $line] 5]
   set rss_enc [lindex [split $line] 6]
   set cmd [lindex [split $line] 2]
   set name [lrange [split $line] 7 end]
   set split_name [rss:wsplit $name "%word%"]
if {[lindex $split_name 1] != ""} {
   putserv "PRIVMSG $chan :\002ID\002: $read_id ; \002Cmd\002: $cmd ; \002Link\002: $link ; \002Name\002: [lindex $split_name 0] ; \002Check_Time\002:$rss_time ; \002News_number\002:$rss_num ; \002Encoding\002:$rss_enc ; \002KeyWord\002:[lindex $split_name 1]"
} else {
   putserv "PRIVMSG $chan :\002ID\002: $read_id ; \002Cmd\002: $cmd ; \002Link\002: $link ; \002Name\002: [lindex $split_name 0] ; \002Check_Time\002:$rss_time ; \002News_number\002:$rss_num ; \002Encoding\002:$rss_enc"
      }
   }
}
if {$found == "0"} {
   putserv "PRIVMSG $chan :No RSS in database for $chan"
   } else {
   putserv "PRIVMSG $chan :End of RSS list"
   }
}


###
proc rss:del {id chan} {
   global rss
   set found 0
   set file [open $rss(filelist) r]
   set read [read -nonewline $file]
   close $file
if {$read == ""} {
   return 0
}
   set valid_id [rss:valid_id $id $chan]
if {$valid_id == "0"} {
   return 0
}
   set timestamp [clock format [clock seconds] -format {%Y%m%d%H%M%S}]
   set temp "$rss(filelist).new.$timestamp"
   set tempwrite [open $temp w]
   set data [split $read "\n"]
foreach line $data {
   set read_id [lindex [split $line] 0]
   set read_channel [lindex [split $line] 1]
if {[string equal -nocase $read_id $id] && [string equal -nocase $chan $read_channel]} {
   set found 1   
   continue
      } else {
   puts $tempwrite $line
      }
   }
   close $tempwrite
       file rename -force $temp $rss(filelist)
   return $found
}


###
proc rss:add {cmd url name chan} {
   global rss
   set rss_num ""
   set rss_time ""
   set rss_word ""
   set rss_enc ""
   set pos [lsearch $name "num=*"]
if {$pos > -1} {
   set split_text [rss:wsplit [lindex $name $pos] "="]
   set get_text [lindex $split_text 1]
if {$get_text != ""} { set rss_num $get_text } else { set rss_num -1 }
   set name [lreplace $name $pos $pos]
}
   set pos [lsearch $name "enc=*"]
if {$pos > -1} {
   set split_text [rss:wsplit [lindex $name $pos] "="]
   set get_text [lindex $split_text 1]
if {$get_text != ""} { set rss_enc $get_text } else { set rss_enc -1 }
   set name [lreplace $name $pos $pos]
}

   set pos [lsearch $name "time=*"]
if {$pos > -1} {
   set split_text [rss:wsplit [lindex $name $pos] "="]
   set get_text [lindex $split_text 1]
if {$get_text != ""} { set rss_time $get_text } else { set rss_time -1 }
   set name [lreplace $name $pos $pos]
}
   set pos [regexp {word=(.*)} $name -> word]
if {[info exists word]} {
   set rss_word $word
   regsub -all -nocase "word=$word" $name "" name
}

if {$rss_num == -1 || ($rss_num != "" && ![regexp {[0-9]} $rss_num])} {
   return [list 2 "Invalid number of RSS news specified"]
}
if {$rss_enc == -1 || ($rss_enc != "" && [lsearch [encoding names] $rss_enc] < 0)} {
   return [list 2 "Invalid encoding specified"]
}
if {$rss_time == -1 || ($rss_time != "" && ![regexp {[0-9]} $rss_time])} {
   return [list 2 "Invalid rss check time specified"]
}
if {$rss_num == ""} { set rss_num $rss(default_check_time)}
if {$rss_time == ""} { set rss_time $rss(news_number)}
if {$rss_word != ""} { set name "$name%word%$rss_word" }
if {$rss_enc == ""} { set rss_enc "-" }
   set check_valid_url [rss:data $url 1]
   switch $check_valid_url {
   1 {
   set check_exists [rss:entry_exists $url $name $cmd $chan]
switch $check_exists {
   0 {
   set id [expr [rss:lastid $chan] + 1]
   set file [open $rss(filelist) a]
   puts $file "$id $chan $cmd $url $rss_time $rss_num $rss_enc $name"
   close $file
   set rss(rss_list) [rss:get_list]
   return 1
   }
   1 {
   return [list 2 "rss command already exists"]
   }
   2 {
   return [list 2 "rss url already exists"]
   }
   3 {
   return [list 2 "rss name already exists"]
      }
   }
}
   2 {
   return [list 0 "couldn't open socket: Name or service not known"]
   }
   3 {
   return [list 0 "no xml items found. Is that an xml page?!"]
   }
   default {
   return [list 0 $check_valid_url]
      }
   }
}

###
proc rss:cmd {nick host hand chan arg} {
   global rss
   set what [lindex [split $arg] 0]
   set cmd [lindex [split $arg] 1]
   set url [lindex [split $arg] 2]
   set name [join [lrange [split $arg] 3 end]]
   switch $what {

   add {
if {![matchattr $hand $rss(rss_add_flags) $chan]} {
   return
}
if {[llength [split $arg]] < 4} {
   putserv "PRIVMSG $chan :Not enough data supplied. Use !rss help / ? for more help."
   return
}
if {![regexp {^(https?|http):\/\/[^\s\/$.?#].[^\s]*$} $url]} {
   putserv "PRIVMSG $chan :Invalid url supplied. Use !rss help / ? for more help."
   return
}
   set add [rss:add $cmd $url $name $chan]
   set status [lindex $add 0]
   set status_reason [lindex $add 1]
switch $status  {
   0 {
   putserv "PRIVMSG $chan :Error. Cannot access URL for checking. Reason: $status_reason"
   }
   1 {
   putserv "PRIVMSG $chan :Added rss to database."
   }
   2 {
   putserv "PRIVMSG $chan :Couldn't add rss. Reason: $status_reason"
   }
}
   }
   list {
if {![matchattr $hand $rss(rss_add_flags) $chan]} {
   return
      }
   rss:list $nick $chan
   }
   del {
if {![matchattr $hand $rss(rss_add_flags) $chan]} {
   return
   }   
if {![regexp {^[0-9]} $cmd]} {
   putserv "PRIVMSG $chan :Couldn't execute. Reason: no valid ID specified"
   return
}
   set status_del [rss:del $cmd $chan]
if {$status_del == 0} {
   putserv "PRIVMSG $chan :Couldn't delete ID $cmd. Reason: no id found"
} else {
   putserv "PRIVMSG $chan :Deleted ID $cmd from database."
if {[file exists "scripts/RSS/$cmd"]} {
   file delete "scripts/RSS/$cmd"
         }
if {[info exists rss(check:$cmd:time)]} {
   unset rss(check:$cmd:time)
}
   set rss(rss_list) [rss:get_list]
      }
   }

   check {
if {![matchattr $hand $rss(rss_add_flags) $chan]} {
   return
   }
if {![regexp {^[0-9]} $cmd]} {
   putserv "PRIVMSG $chan :Couldn't execute. Reason: no valid ID specified"
   return
}   
   set valid_id [rss:valid_id $cmd $chan]
if {$valid_id == "0"} {
   putserv "PRIVMSG $chan :Couldn't check ID \002$cmd\002. Reason: no id found"
   return
   }
   set url [rss:link_byid $cmd $chan]
   set check_valid_url [rss:data $url 1]
   switch $check_valid_url {
   1 {
   putserv "PRIVMSG $chan :RSS \002$cmd\002 check results : \002OK\002"
   }
   2 {
   putserv "PRIVMSG $chan :RSS \002$cmd\002 check results : \002couldn't open socket: Name or service not known\002"
   }
   3 {
   putserv "PRIVMSG $chan :RSS \002$cmd\002 check results : \002no xml items found. Is that an xml page?!\002"
   }
   default {
   putserv "PRIVMSG $chan :RSS \002$cmd\002 check results : \002check_valid_url\002"
      }
   }
}
   help {
if {![matchattr $hand $rss(rss_add_flags) $chan]} {
   return
}   
   putserv "NOTICE $nick :\002RSS\002 Help : \002!rss\002 - shows the ID's and the commands for the RSS added ; \002!rss add <rss cmd> <link> <name>\002 \[num=X time=X enc=X word=X,Y,Z\] ; \002!rss list\002 ; \002!rss del <id>\002 ; \002!rss check <link>\002 (checks a RSS link)"
   }
   default {
if {![matchattr $hand $rss(rss_show_flags) $chan]} {
   return
}
if {![info exists rss(rss_list)]} {
   set get_list [rss:get_list]
if {$get_list == ""} {
   putserv "PRIVMSG $chan :No RSS cmds added for \002$chan\002."
   return
   }
}
   set data [split $rss(rss_list) "\n"]
   set cmds ""
foreach line $data {
   set read_chan [lindex $line 1]
if {[string equal -nocase $chan $read_chan]} {
   set id [lindex $line 0]
   set cmd [lindex $line 2]
   lappend cmds "\#$id $cmd"
   }
}
if {$cmds == ""} {
   putserv "PRIVMSG $chan :No RSS cmds added for \002$chan\002."
   return
}
   set cmds [join $cmds ", "]
foreach w [rss:wrap $cmds 400 ","] {
   putserv "PRIVMSG $chan :\002RSS\002 Cmds \[#ID\]: $w"
         }
      }
   }
}

###
# Credits
set rss(projectName) "BlackRSS TCL"
set rss(author) "BLaCkShaDoW"
set rss(website) "wWw.TclScripts.Net"
set rss(email) "blackshadow@tclscripts.net"
set rss(version) "v1.0"


#http://wiki.tcl.tk/989
proc rss:wsplit {string sep} {
    set first [string first $sep $string]
    if {$first == -1} {
        return [list $string]
    } else {
        set l [string length $sep]
        set left [string range $string 0 [expr {$first-1}]]
        set right [string range $string [expr {$first+$l}] end]
        return [concat [list $left] [rss:wsplit $right $sep]]
    }
}

###
proc b0:short {link} {
   set link "http://b0.ro/api/?key=ZLo6F8qQzCPS&url=$link"
   set ipq [http::config -useragent "lynx"]
   set error [catch {set ipq [::http::geturl "$link" -timeout 10000]} eror]
   set status [::http::status $ipq]
if {$status != "ok"} {
   ::http::cleanup $ipq
   return $link
}
   set data [http::data $ipq]
   ::http::cleanup $ipq
   regexp {"short":(.*)} $data -> short_link
    return [string map { "\"" ""
              "\}" ""
              "\\" ""} $short_link]
}

###
proc rss:wrap {str {len 100} {splitChr { }}} {
   set out [set cur {}]; set i 0
   foreach word [split [set str][unset str] $splitChr] {
     if {[incr i [string len $word]]>$len} {
         lappend out [join $cur $splitChr]
         set cur [list $word]
         set i [string len $word]
      } {
         lappend cur $word
      }
      incr i
   }
   lappend out [join $cur $splitChr]
}

putlog "\002$rss(projectName) $rss(version)\002 coded by\002 $rss(author)\002 ($rss(website)): Loaded & initialised.."

#######################
#######################################################################################################
###                  *** END OF BlackTrivia TCL ***                                                 ###
####################################################################################################### 

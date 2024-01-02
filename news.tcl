# CNN news.tcl V1.1
# by Thrill
# 
# All newsheadlines parsed by this script are (C) cnn.com 
# 
# Version History: V1.0  - first public release
#                  V1.01 - stupid bug ('putchan') fixed
#                  V1.1  - added URL's to the newsitem.
# Remember to change this script before implementing it! Remove/comment the 'die "CNN News not changed!"' afterwards.
# Only the location of lynx needs change. 
#
# The author takes no responsibility whatsoever for the usage and working of this script !
# 
# E-mail: jmildham59@hotmail.com

# default bind command !news, change to your liking
bind pub - "!news" news

# set the location of lynx here. Normally this should be ok.
set lynx "/usr/bin/lynx"

#set locations of tempfiles here, default /tmp/newstmp1.txt, newstmp2.txt should be ok
set ftemp1 "/tmp/newstmp1.txt"
set ftemp2 "/tmp/newstmp2.txt"

# comment or remove this when you are done
#die "CNN News not changed!"
# see function PARSE below for the output-string, which can be changed if you like, example included.

#### DO NOT EDIT BELOW - EVERY CHANGE IS ON YOUR OWN RISK AND COULD LEAD THIS SCRIPT TO FAIL! ####

#define all strings here
set topstories    "TOP STORIES"
set world         "WORLD"
set us            "US"
set politics      "POLITICS"
set weather       "WEATHER"
set business      "BUSINESS from CNNfn.com"
set sports        "SPORTS from CNNSI.com"
set technology    "TECHNOLOGY"
set space         "SPACE"
set health        "HEALTH"
set entertainment "ENTERTAINMENT"
set travel        "TRAVEL"

################
# Function: news
# Purpose : public function called by the bind !news, selects user-choice and forwards to 'parse'-function
proc news { nick uhost handle chan arg } {
  global topstories world us politics weather business sports technology space health entertainment travel
   if {[llength $arg]==0} {
      putserv "PRIVMSG $chan :Please enter which news you would like to read (!news help)"
   } else {
      if { [lindex $arg 0] == "help" } {
        putserv "notice $nick :CNN News v1.1 - www.cnn.com - by Thrill"
        putserv "notice $nick :Usage: !news <item>"
        putserv "notice $nick :where <item> is one of the following:"
        putserv "notice $nick :top     - Top Stories    , world     - World News"
        putserv "notice $nick :us      - US News        , politics  - Politics News"
        putserv "notice $nick :weather - Weather News   , business  - Business News"
        putserv "notice $nick :tech    - Technology News, space     - Space News"
        putserv "notice $nick :health  - Health News    , entertain - Entertainment News"
        putserv "notice $nick :sports  - Sports News    , travel    - Travel News"
      } else { 
        # first get the news into the two tempfiles, seperated on headlines and references
        getnews $nick $chan        
        # now parse the selected news to the chan
        switch [lindex $arg 0] {
        "top" {
            putchan $chan "3CNN Top Stories Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $topstories
          }
        "world"  {
            putchan $chan "3CNN World News Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $world
          }
        "us"  {
            putchan $chan "3CNN US Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $us
          }
       "politics" {
            putchan $chan "3CNN Politics Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $politics
          }
       "weather"  {
            putchan $chan "3CNN Weather Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $weather
          }
       "business"  {
            putchan $chan "3CNN Business Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $business
          }
       "tech" {
            putchan $chan "3CNN Technology Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $technology
          }
       "space" {
            putchan $chan "3CNN Space Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $space
          }
       "health" {
            putchan $chan "3CNN Health Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $health
          }
       "entertain" {
            putchan $chan "3CNN Entertainment Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $entertainment
          }
       "sports" {
            putchan $chan "3CNN Sports Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $sports
          }
       "travel" {
            putchan $chan "3CNN Travel Headlines (c) CNN.com - by Thrill"
            parse $nick $uhost $handle $chan $travel
          }
       default { 
            # user pasted some weird other string after !news ... ; fetch default Top Stories
            putchan $chan "3CNN Top Stories Headlines (c) CNN.com - by Thrill \"!news help\" for options "
            parse $nick $uhost $handle $chan $topstories
          }
        }    
     }  
  }
}

################
# Function: getnews
# Purpose : private function which acquires the news from www.cnn.com, and parses it into two tempfiles
#           the first containing the headlines, the second the URL-references
proc getnews { nick chan } {
  global ftemp1 lynx ftemp2
  set fnews [open "|$lynx -preparsed -dump www.cnn.com/desktop/content.html" r]
  set temp1 [open "$ftemp1" w]
  set temp2 [open "$ftemp2" w]
  
  while { [eof $fnews] != 1 } {
  # put top of file into first tempfile
    set templine "[gets $fnews]"
    if { [string last "References" $templine] != -1 } {
      break
    }
    puts $temp1 $templine
  }
  
  close $temp1    
  puts $temp2 $templine
  while { [eof $fnews] != 1 } {
  # put references in second tempfile
    set templine "[gets $fnews]"
    puts $temp2 $templine
  }
  close $temp2
  close $fnews
}

################
# Function: parse
# Purpose : private function which actually parses two tempfiles made by 'getnews' and outputs the contents based on the 
#           selection parameter $arg together with the URL appended to it. 
proc parse { nick uhost handle chan arg } {
  global ftemp1 lynx ftemp2
  # newsfile
  set temp1 [open "$ftemp1" r]
  # references file
  set temp2 [open "$ftemp2" r]
  # number used for referencing with headline file
  set tempnumber ""
  # url counter for references file, leave to 1 (first reference)
  set temp2count 1
  #get first two non-important lines from temp2 and finally the first url, never mind the if-eof, just for certainty
  for { set counter 1 } { $counter < 4 } { incr counter } {
    if {[eof $temp2] != 1} {
      set tempurl "[gets $temp2]"
    }
  }
  # get first line of headline file
  if {[eof $temp1] != 1} {
    set templine "[gets $temp1]"
  }
  while {[eof $temp1] != 1} {
    set templine "[gets $temp1]"
    if {[string last $arg $templine] != -1} {
      # get empty line
      set templine "[gets $temp1]"
      # paste other lines until empty line <= 5 characters
      set templine "[gets $temp1]"
      while { [string length $templine] > 5 } {
      # get the url-number from this string 
        set counter1 0
        set counter2 1
        #get first part of number, search for "* " at start of line and skip "["
        while { ([string range $templine $counter1 $counter2] != "* ") && ($counter1 != [string length $templine]) } {
           incr counter1
           incr counter2 
        }
        incr counter2 2
        # get number upto ']'
        while { ([string range $templine $counter2 $counter2] != "]") && ($counter1 != [string length $templine]) } {
          append tempnumber [string range $templine $counter2 $counter2]
          incr counter2 
        }
        incr counter2
        
        # get the reference from temp2
        while {([eof $temp2] != 1) && ($temp2count < $tempnumber) } {
          set tempurl "[gets $temp2]"
          incr temp2count
        }
        
# POSSIBLE CHANGEME put the line to irc with colours, if you hate to display the url, change its colour to 0 (white)
# users can still click it, but it will be (mostly) invisible
# you can put the following code instead (uncomment, comment the other) for a different way of displaying the URL
#  putchan $chan "12 [string range $templine $counter2 end] 5Click: [string range $tempurl 6 23]0[string range $tempurl 24 end]"
# which makes the URL white except for www.cnn.com, so the screen looks not too cluttered (tested with ordinary Mirc, not BitchX..)
        putchan $chan "12 [string range $templine $counter2 end] 5([string range $tempurl 6 end])"
        set templine "[gets $temp1]"
        set tempnumber ""
      }
      break
    }
  }
  close $temp1
  close $temp2
}

proc putchan {chan msg} { putserv "PRIVMSG $chan :$msg" }

putlog "CNN News v1.1 by Thrill - Loaded."

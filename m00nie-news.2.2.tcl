################################################################################################
# Name			m00nie::news
# Description		Uses newsapi.org to find some recent new for various sites. Also allows
#               	users to specify their own default news site thats checked for them
#
# Version		2.2 - Adds default country option (set defaultnews variable)
# 			2.1 - Actually making 2.0 work.....
# 			2.0 - Updates to API v2 (LOTS more feeds) plus fixes the TLS config
# 			  since the site now sites behind cloudflare and _requires_ server
# 			  names to be sent. Small work around for people who have old packages 
# 			  like I did. This update also adds per user and per channel throttling
# 			1.0 - Initial release
# Website		https://www.m00nie.com/news-script-for-eggdrop-bot/
# Notes			Grab your own key @ https://newsapi.org/register
################################################################################################
namespace eval m00nie {
   namespace eval news {
	package require http
	package require json
	# We need to verify the revision of TLS since prior to this version is missing auto host for SNI 
	if { [catch {package require tls 1.7.11}] } {
    		# We dont have an autoconfigure option for SNI
    		putlog "m00nie::news *** WARNING *** OLD Version of TLS package installed please update to 1.7.11+ ... Slightly hacky work around in the meantime :0"
		http::register https 443 [list ::tls::socket -servername newsapi.org]
	} else {
    		package require tls 1.7.11
		http::register https 443 [list ::tls::socket -autoservername true]
	}
	# If you'd like to set a default news source enter the two letter country below. If the
	# user has not set a country code as a fav this will be used instead. You can also comment
	# out the !setnews bind to remove the option for users to specify their own source. If 
	# the defaultnews variable is left blank the user will be prompted to set their own though. 
	variable defaultnews ""
	bind pub - !setnews m00nie::news::source
        bind pub - !news m00nie::news::search

	variable version "2.2"
	setudef flag news
	# This needs to be your own key sign up at the URL above in the notes
	variable key "425483419cd740c3b2339f2f2a3381a1425483419cd740c3b2339f2f2a3381a1"
	# Set the following to the number of seconds for channel and user throttling
	variable user_throt 300
    	variable chan_throt 10
	::http::config -useragent "Mozilla/5.0 (X11; CrOS x86_64 12739.105.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.158 Safari/537.36"
	# Leave this alone
	variable throttled

proc throttlecheck {nick chan} {
	if {[info exists m00nie::news::throttled($chan)]} {
		putlog "m00nie::news::throttlecheck $chan is throttled at the moment"
		return 1
	} elseif {[info exists m00nie::news::throttled($nick)]} {
		putlog "m00nie::news::throttlecheck $nick is throttled at the moment"
		return 1
	} else { 
		set m00nie::news::throttled($nick) [utimer $m00nie::news::user_throt [list unset m00nie::news::throttled($nick)]]
		set m00nie::news::throttled($chan) [utimer $m00nie::news::chan_throt [list unset m00nie::news::throttled($chan)]]
		return 0
	}
}	

proc chkloc {cc} {
	putlog "m00nie::news::chkloc looking for $cc"
	set des ""
	set sources [list ar Argentina au Australia at Austria be Belgium br Brazil bg Bulgeria ca Canada cn China co Colombia cu Cuba cz {Czech Republic} eg Egypt fr France de Germany gr Greece hk {Hong Kong} hu Hungary in India id Indonesia ie Ireland il Israel it Italy jp Japan lv Latvia lt Lithuania my Malaysia mx Mexico ma Morocco nl Netherlands nz {New Zealand} ng Nigeria no Norway ph Philippines pl Poland pt Portugal ro Romania ru Russia sa {Saudi Arabia} rs Serbia sg Singapore sk Slovakia si Slovenia za {South Africa} kr {South Korea} se Sweden ch Switzerland tw Taiwan th Thailand tr Turkey ae UAE ua Ukraine  gb {United Kingdon} us {United States} vs Venuzuela ]
	# See if we have the source the user would like
        set result [lsearch -exact $sources $cc]
	if { $result >= 0 } {
		putlog "m00nie::news::chkloc found $cc and name is [lindex $sources [expr $result +1]]"
		set des [lindex $sources [expr $result +1]]
	}
	return [list $result $des]
}
	
# Allow a user to save their choice of news source
proc source {nick uhost hand chan text} {
      	putlog "m00nie::news::source nick: $nick, uhost: $uhost, hand: $hand"

	set newsloc [string tolower [string trim $text]]
      	if {!([string length $newsloc] eq 2)} {
          	puthelp "PRIVMSG $chan :Please enter the two character country/region code. Pick one from https://newsapi.org/sources"
          	return
      	}

	set chk [chkloc $newsloc]
	set result [lindex $chk 0]
	if { $result < 0 } {
                puthelp "PRIVMSG $chan :Couldn't find source $newsloc. Pick one from https://newsapi.org/sources"
                return
        }
	set des [lindex $chk 1]

      	putlog "m00nie::news::source found $newsloc ($des) at $result"

      	if {![validuser $hand]} {
          	adduser $nick
          	set mask [maskhost [getchanhost $nick $chan]]
          	setuser $nick HOSTS $mask
          	chattr $nick -hp
          	putlog "m00nie::news::source added user $nick with host $mask"
      	}
      	setuser $hand XTRA m00nie:news.newsloc $newsloc
	setuser $hand XTRA m00nie:news.newsdes $des
      	puthelp "PRIVMSG $chan :set default news region to $des ($newsloc)"
      	putlog "m00nie::news::source $nick set their default source to $newsloc ($des)"
}

proc getinfo { url } {
	putlog "m00nie::news::getinfo grabbing: $url"
	for { set i 1 } { $i <= 5 } { incr i } {
        	set rawpage [http::data [http::geturl "$url" -timeout 5000]]
        	if {[string length rawpage] > 0} { break }
        }
        putlog "m00nie::news::getinfo Rawpage length is: [string length $rawpage]"
        if {[string length $rawpage] == 0} { error "newsapi returned ZERO no data :( or we couldnt connect properly" }
	set json [json::many-json2dict $rawpage]
	return $json

}

proc search {nick uhost hand chan text} {
        # Check chanset and no throttling enabled
	if {![channel get $chan news] } {
                return
        }
        if {[throttlecheck $nick $chan]} { return 0 }
	
	putlog "m00nie::news::search is running"
	
	# Get users saved news feed if none prompt for one
	set source [getuser $hand XTRA m00nie:news.newsloc]
  	set name [getuser $hand XTRA m00nie:news.newsdes]
  	
	if {((([string length $source] <= 0) || ([string length $name] <= 0)) && ([string length $m00nie::news::defaultnews] < 2))} {
      		puthelp "PRIVMSG $chan :No default news source found for you. Please set one using !setnews or specify a default source"
      		return
  	} elseif { (([string length $source] <= 0) || ([string length $name] <= 0) && ([string length $m00nie::news::defaultnews] eq 2))} {
		set chk [chkloc $m00nie::news::defaultnews]
		set result [lindex $chk 0]
		if { $result < 0 } {
                	puthelp "PRIVMSG $chan :Couldn't find default source $m00nie::news::defaultnews. Pick one from https://newsapi.org/sources"
                	return
        	}
        	set source $m00nie::news::defaultnews
		set name [lindex $chk 1]
	} else {
		putlog "m00nie::news::search ..... something odd happened"
	}


  	putlog "m00nie::news::search Grabbing news for $nick, with source of $source and name of $name"
	set url "http://newsapi.org/v2/top-headlines?country=$source&apiKey=$m00nie::news::key"
	set news [getinfo $url]

	for {set i 0} {$i < 3} {incr i} {
   		set title [encoding convertfrom [lindex $news 0 5 $i 5]]
		set url [lindex $news 0 5 $i 9]
		set pub [lindex $news 0 5 $i 13]
    		if { $i == 0 } {
		    set output "Top stories from $name: \002$title\002 - $url (@$pub)"
    		} else {
        		set output "\002$title\002 - $url (@$pub)"
    		}
    		puthelp "PRIVMSG $chan :$output"
	}
}
}
}
putlog "m00nie::news $m00nie::news::version loaded"

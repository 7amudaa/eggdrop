#############################################
#  gconvert.tcl v2.0       by AkiraX        #
#                    <#AnimeFiends@EFNet>   #
#############################################

####### DESCRIPTION #########################
# Uses the google calculator to perform
# conversions and mathematics
#############################################

####### USAGE ###############################
# !convert <quantity> to <quantity>
# !math <equation> : perform mathematics
# !calc <equation> : same as !math
#############################################

####### CHANGELOG ###########################
# v2.1 : fixed functionality, repaired by Scott Glover 
# v2.0 : allow convert code to perform math
# v1.0 : support for google conversions
#############################################

####### LICENSE ############################# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, U
#############################################

package require http

bind pub -|- !convert gconvert:run
proc gconvert:run { nick host handle chan text } {
	set convert(nick) [join [lrange [split $nick] 0 0]]
	set convert(input) [join [lrange [split $text] 0 end]]

	# create google URL
	set token [http::config -useragent "Mozilla"]
	set convert(url) [gconvert:webstring "convert $convert(input)"]
	set convert(url) "http://www.google.com/search?hl=en&q=$convert(url)"

	set num_tries 0
	set try_again 1
	while { $try_again } {
		incr num_tries
		if { $num_tries > 3 } {
			set try_again 0
			break
		}

		# grab the info from google
		set token [http::geturl $convert(url) -timeout 15000]
		upvar #0 $token state
		if { $state(status) == "timeout" } {
			puthelp "PRIVMSG $chan :Sorry, your request timed out."
			return
		}
		set convert(html) [split [http::data $token] "\n"]
		http::cleanup $token

		# find the answer
		set num_lines 0
		set convert(answer) ""
		foreach line $convert(html) {
			incr num_lines
			if { $num_lines > 100 } {
				set try_again 0
				break
			}
			
			# take suggestions
			if { [regexp {Did you mean:} $line] } {
				# grab the new URL and start over
				regexp {Did you mean: </font><a href=(.*?) class=p>} $line match convert(url)
				set convert(url) "http://www.google.com$convert(url)"
				break
			}

			# find the calculator
			if { [regexp {src=/images/calc_img.gif} $line] } {
				regexp {src=/images/calc_img.gif alt=""></td><td>&nbsp;</td><td nowrap>(.*?)</td>} $line match convert(answer)
				regexp {<b>(.*?)</b>} $convert(answer) match convert(answer)
				set try_again 0
				break
			}
		}
	}

	if { $convert(answer) == "" } {
		puthelp "PRIVMSG $chan :Sorry, didn't work out."
		return
	}

	puthelp "PRIVMSG $chan :[gconvert:gstring $convert(answer)]"

	return
}

bind pub -|- !math gconvert:math
bind pub -|- !calc gconvert:math
proc gconvert:math { nick host handle chan text } {
	set calc(nick) [join [lrange [split $nick] 0 0]]
	set calc(input) [join [lrange [split $text] 0 end]]

	# create google URL
	set token [http::config -useragent "Mozilla"]
	set calc(url) [gconvert:webstring "$calc(input)"]
	set calc(url) "http://www.google.com/search?hl=en&q=$calc(url)"

	set num_tries 0
	set try_again 1
	while { $try_again } {
		incr num_tries
		if { $num_tries > 2 } {
			set try_again 0
			break
		}

		# grab the info from google
		set token [http::geturl $calc(url) -timeout 15000]
		upvar #0 $token state
		if { $state(status) == "timeout" } {
			puthelp "PRIVMSG $chan :Sorry, your request timed out."
			return
		}
		set calc(html) [split [http::data $token] "\n"]
		http::cleanup $token

		# find the answer
		set num_lines 0
		set calc(answer) ""
		foreach line $calc(html) {
			incr num_lines
			if { $num_lines > 100 } {
				set try_again 0
				break
			}

			# take suggestions
			if { [regexp {Did you mean:} $line] } {
				# grab the new URL and start over
				regexp {Did you mean: </font><a href=(.*?) class=p>} $line match calc(url)
				set calc(url) "http://www.google.com$calc(url)"
				break
			}

			# find the calculator
			if { [regexp {src=/images/calc_img.gif} $line] } {
				regexp {src=/images/calc_img.gif alt=""></td><td>&nbsp;</td><td nowrap>(.*?)</td>} $line match calc(answer)
				regexp {<b>(.*?)</b>} $calc(answer) match calc(answer)
				set try_again 0
				break
			}
		}
	}

	if { $calc(answer) == "" } {
		puthelp "PRIVMSG $chan :Sorry, didn't work out."
		return
	}

	puthelp "PRIVMSG $chan :[gconvert:gstring $calc(answer)]"

	return
}

proc gconvert:webstring { input } {
	set input [string map { {%} {%25} } $input]
	set input [string map { {&} {&amp;} } $input]
	set input [string map { {*} {%2A} } $input]
	set input [string map { {+} {%2B} } $input]
	set input [string map { {,} {%2C} } $input]
	set input [string map { {-} {%2D} } $input]
	set input [string map { {/} {%2F} } $input]
	set input [string map { {^} {%5E} } $input]
	set input [string map { {<} {&lt;} } $input]
	set input [string map { {>} {&gt;} } $input]
	#set input [string map { {"} {&quot;} } $input]
	set input [string map { {"} {} } $input]
	set input [string map { {'} {&#039;} } $input]
	set input [string map { { } {+} } $input]

	return $input
}

proc gconvert:gstring { input } {
	set input [string map { {<font size=-2> </font>} {,} } $input]
	set input [string map { {&#215;} {x} } $input]
	set input [string map { {10<sup>} {10^} } $input]
	set input [string map { {</sup>} {} } $input]

	return $input
}

putlog "gconvert.tcl v2.0 by AkiraX <#AnimeFiends@EFnet> loaded!"

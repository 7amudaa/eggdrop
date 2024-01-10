# antsy's cryptocurrency price check script


package require Tcl
package require http
package require json
package require tls

namespace eval cryptocheck {

# Eggdrop bindings
bind pub - !crypto [namespace current]::cryptocheckpub
bind msg f !crypto [namespace current]::cryptocheckmsg

# Global variables
set ccVersion "Cryptocurrency price check script 1.0"
set outputCurrency "eur"
set outputSymbol "€"

putlog "Loaded script $ccVersion"

##
# Handler for calling the script via public message
#
# @param nick    User nickname
# @param host    User hostname
# @param handle  User in bot
# @param channel Channel
# @param text    Parameters
proc cryptocheckpub {nick host handle channel text} {
  putlog "Cryptocurrency check: $nick ($handle/$host) requested \[$text\] at $channel"
  if {$text == ""} {
    variable ccVersion
    msg $channel "$ccVersion - Usage: !crypto <bitcoin/ethereum/ripple/etc...> (you can query multiple, separated by space)"
    return
  }
  # Clean input
  set text [string trim $text]

  set currency [split $text " "]
  set output [fetch $currency]
  putlog $output
  set output [prettyPrint $output]
  putlog $output

  set length [string length $output]
  if {$length > 1} {
    msg $channel $output
  }
}

##
# Handler for calling the script via public message
#
# @param nick    User nickname
# @param uhost   User hostname
# @param handle  User in bot
# @param text    Parameters
proc cryptocheckmsg {nick uhost handle text} {
  putlog "Cryptocurrency check: $nick ($handle!$uhost) requested \[$text\] as privmsg"
  if {$text == ""} {
    variable ccVersion
    msg $nick "$ccVersion - Usage: !crypto <bitcoin/ethereum/ripple/etc...> (you can query multiple, separated by space)"
    return
  }
  # Clean input
  set text [string trim $text]

  set currency [split $text " "]
  set output [fetch $currency]
  set output [prettyPrint $output]

  set length [string length $output]
  if {$length > 1} {
    msg $nick $output
  }
}

##
# Send response to user.
# Separates output to multiple lines if the message is too long (for IRCnet)
#
# @param dest   Target, can be nick or channel.
# @param data   The message.
proc msg {dest data} {
   set len [expr {512-[string len ":$::botname PRIVMSG $dest :\r\n"]}]
   foreach line [wordwrap $data $len] {
      puthelp "PRIVMSG $dest :$line"
   }
}

##
# Format the result data
#
# @param coinData   Result data Dictionary from Coingecko
# @return           Message formatted for IRC
proc prettyPrint { data } {
  set output [list]
  variable outputCurrency
  variable outputSymbol
  dict for {coinName coinData} $data {
    dict with coinData {
      set coinValue [subst $$outputCurrency]
      if {$coinValue > 0.001} {
        # Round to 3 decimals unless value is really small
        set coinValue [format {%0.3f} $coinValue]
      }
      set valueChange [formatValueChange $eur_24h_change]
      set outdatedWarning [checkLastUpdated $last_updated_at]
      set additionalInfo [join [list " (" $valueChange "%)"] ""]
      if {$outdatedWarning != ""} {
        # Really it makes no sense to display 24h values if the value is old so let's display warning message there instead
        set additionalInfo [join [list " (" [colorize $outdatedWarning 5] ")"] ""]
      }

      set str [join [list $coinName ": " [bold $coinValue] $outputSymbol $additionalInfo] ""]
      lappend output $str
    }
  }

  return [join $output " "]
}

##
# Format value change percentage
#
# @param  eur_24h_change  Change in the last twenty four hours
# @return                 Formatted string
proc formatValueChange {eur_24h_change} {
  set valueChange "0.0"
  if [string is double -strict $eur_24h_change] {
    set valueChange [format {%+0.2f} $eur_24h_change]
  }

  if {$eur_24h_change > 0} {
    # Value gone up, color it green
    set valueChange [colorize $valueChange 3]
  } else {
    # Value gone down, color it red
    set valueChange [colorize $valueChange 4]
  }

  return $valueChange
}

##
# Check if the value is too old (older than one hour)
#
# @param  last_updated_at  UNIX timestamp
# @return                  Error message
proc checkLastUpdated {last_updated_at} {
  set now [clock seconds]
  set oneHour 3600
  set timeDiff [expr {$now - $last_updated_at}]
  if {$timeDiff > $oneHour} {
    set hours [expr {$timeDiff / $oneHour}]
    set hours [expr {round($hours)}]
    if {$hours == 1} {
      set warningText "Warning! the value is hour old"
    } else {
      set warningText "Warning! the value is $hours hours old"
    }
    if {$hours > 23} {
      set days [expr {$hours / 24}]
      set days [expr round($days)]
      if {$days == 1} {
        set warningText "Warning! the value is day old"
      } else {
        set warningText "Warning! the value is $days days old"
      }
    }
    return [colorize $warningText 6]
  }
  return ""
}

##
# Colorize string and reset back to default color
#
# @param str    String to be colorized
# @param color  VGA color
proc colorize {str color} {
  set output "\003$color"
  append output $str
  append output "\003"
  return $output
}

##
# Bold string
#
# @param  str   Input string
# @return       Formatted string
proc bold {str} {
  return "\002$str\002"
}

##
# Fetches the prices from the Coingecko's free API.
#
# @see https://www.coingecko.com/api/documentations/v3
#
# @param currency    Currency or currencies to check
# @return {dict}     Result from request
proc fetch { currency } {
  variable ccVersion
  variable outputCurrency
  set ids [join $currency "%2C"]
  set url "https://api.coingecko.com/api/v3/simple/price?ids=${ids}&vs_currencies=${outputCurrency}&include_last_updated_at=true&include_24hr_change=true"

  ::http::register https 443 [list ::tls::socket -autoservername true -require 0 -request 1]
  set token [http::config -useragent "$ccVersion"]
  set token [http::geturl $url]

  set result [json::json2dict [http::data $token]]

  http::cleanup $token
  return $result
}

} ;#end namespace

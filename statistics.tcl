# Statistics.tcl (C) 2004 perpleXa
#  type ".chanset <chan> +stat" on the partyline to ativate the script for a specific channel.
#  commands: $stat <nick> - shows information about you or a nick. (works only for other nicks when you are op on a channel)
#            $top10 <smilies|words|lines|letters> - shows the top10 chatters, default option is words
#            $top20 <smilies|words|lines|letters> - same as $top10 but with places 11-20

namespace eval statistics {
# Storage file
  variable storage {scripts/dbase/statistics}

# Kill unused entries after x days
  variable killafter 30

# Command trigger
  variable trigger {@}

# smiley regex (only touch this, if you really know, what you are doing!)
  variable smileyregex {(:|8|;)(-|o)?(>|<|D|O|o|\)|\(|\]|\[|P|p|\||\\|/)}

  bind PUB   -|-  ${trigger}stat   [namespace current]::spew
  bind PUB   -|-  ${trigger}top10  [namespace current]::toplist
  bind PUB   -|-  ${trigger}top20  [namespace current]::toplist
  bind PUBM  -|-  *                [namespace current]::monitor
  bind CTCP  -|-  ACTION           [namespace current]::ctcp
  bind EVNT  -|-  save             [namespace current]::save
  bind TIME  -|-  {00 * * * *}     [namespace current]::cleanupdb

  setudef flag stat

  namespace export spew top10 toplist save load monitor
}

proc statistics::ctcp {nickname hostname handle target keyword arguments} {
  if {[validchan $target]} {
    monitor $nickname $hostname $handle $target $arguments
  }
  return 0
}

proc statistics::monitor {nickname hostname handle channel arguments} {
  variable data
  variable smileyregex
  if {([isbotnick $nickname]) || (![channel get $channel stat])} {
    return 0
  }
  set hostname [maskhost *!$hostname]
  regsub -all -- {\002|\003[\d]{0,2}(,[\d]{0,2})?|\006|\007|\017|\026|\037|\n|\t} $arguments {} arguments
  set added(words) [regexp -all -- {\S+} $arguments]
  set added(letters) [regexp -all -- {\S} $arguments]
  if {[string length $smileyregex] >= 1} {
    set added(smilies) [regexp -all -- $smileyregex $arguments]
  } else {
    set added(smilies) 0
  }
  if {(![info exists data($channel,$hostname)])} {
    set data($channel,$hostname) "0 0 0 0 0 NULL"
  }
  regexp -- {^(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\S+)$} $data($channel,$hostname) -> lastseen lines words letters smilies lastnick
  incr lines 1
  incr words $added(words)
  incr letters $added(letters)
  incr smilies $added(smilies)
  set data($channel,$hostname) "[unixtime] $lines $words $letters $smilies $nickname"
}

proc statistics::spew {nickname hostname handle channel arguments} {
  variable data
  if {(![channel get $channel stat])} {
    return 0
  }
  if {([isop $nickname $channel]) && ([string length $arguments] >= 1)} {
    set target [lindex [clean $arguments] 0]
  } else {
    set target $nickname
  }
  if {![onchan $target $channel]} {
    putserv "PRIVMSG $channel :\[Statistics - Unknown user \002$target\002\]"
    return 0
  }
  set targethost [maskhost *![getchanhost $target $channel]]

  if {[info exists data($channel,$targethost)]} {
    regexp -- {^(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\S+)$} $data($channel,$targethost) -> lastseen lines words letters smilies lastnick
    set wpl [round [expr ($words / $lines.)]]
    set spl [round [expr ($smilies / $lines.)]]
    set lpw [round [expr ($letters / $words.)]]
    putserv "PRIVMSG $channel :\[Statistics - \002$target\002 has written \002$lines\002 lines, \002$words\002 ($wpl per line) words and \002$letters\002 ($lpw per word) letters, containing \002$smilies\002 ($spl per line) smilies\]"
  } else {
    putserv "PRIVMSG $channel :\[Statistics - No valuable information available for \002$target\002\]"
  }
}

proc statistics::top {channel number {type ""}} {
  variable data
  set statistics {}
  switch $type {
    {lines} {set index 1}
    {letters} {set index 3}
    {smilies} {set index 4}
    {default} {set index 2 ; set type "words"}
  }
  foreach {user stats} [array get data $channel,*] {
    set stats [clean $stats]
    lappend statistics "[lindex [clean $stats] 5] [lindex $stats $index]"
  }
  set statistics [lrange [lsort -integer -decreasing -index 1 [lsort -unique -index 0 [lsort -integer -increasing -index 1 $statistics]]] [expr $number - 10] [expr $number - 1]]
  if {$statistics == ""} {
    return "\[Top$number $type - No valuable information available for \002$channel\002\]"
  }
  set output "\[Top$number $type -"
  for {set i 0} {$i < [llength $statistics]} {incr i 1} {
    set item [lindex $statistics $i]
    append output "\x20[expr $i+$number-9]: \002[join [lindex [clean $item] 0] { }]\002 ([lindex $item 1])"
  }
  append output "\]"
  return $output
}

proc statistics::toplist {nickname hostname handle channel arguments} {
  global lastbind
  if {(![channel get $channel stat])} {
    return 0
  }
  set arguments [clean $arguments]
  set key [lindex $arguments 0]
  if {![regexp -- {^.*?([0-9]+)$} $lastbind -> number]} {
    return 0
  }
  if {![regexp -nocase -- {^(words|letters|smilies|lines|)$} $key]} {
    putserv "PRIVMSG $channel :\[Statistics - Unknown option: \002$key\002, valid options are \002letters\002, \002lines\002, \002smilies\002 and \002words\002\]"
    return 0
  }
  putserv "PRIVMSG $channel :[top $channel $number [string tolower $key]]"
}

proc statistics::cleanupdb {args} {
  variable killafter
  variable data
  set killed 0
  foreach {item} [array names data] {
    set lastseen [lindex [clean $data($item)] 0]
    set expire [expr 60 * 60 * 24 * $killafter]
    if {[expr [unixtime] - $lastseen] >= $expire} {
      incr killed
      unset data($item)
    }
  }
  return $killed
}

proc statistics::load {} {
  variable data
  variable storage
  regexp -- {^(\S+/)?.*$} $storage -> directory
  if {[string length $directory] >= 1} {
    if {![file isdirectory $directory]} {
      file mkdir $directory
    }
  }
  if {![file exists $storage]} {
    return 0
  }
  if {[array exists data]} {
    array unset data
  }
  set file [open $storage r]
  while {![eof $file]} {
    gets $file line
    if {[regexp -nocase -- {^channel:(\S+)\sid:(\S+)\svalue:(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\S+)$} $line -> channel hostname lastseen lines words letters smilies lastnick]} {
      set data($channel,$hostname) "$lastseen $lines $words $letters $smilies $lastnick"
    }
  }
  close $file
}

proc statistics::save {args} {
  variable data
  variable storage
  set file [open $storage w]
  foreach chan_user [array names data] {
    regexp {^(\S+),(\S+)$} $chan_user -> channel user
    puts $file "channel:$channel id:$user value:$data($chan_user)"
  }
  close $file
}

proc statistics::clean {i} {
  regsub -all -- \\\\ $i \\\\\\\\ i
  regsub -all -- \\\[ $i \\\\\[ i
  regsub -all -- \\\] $i \\\\\] i
  regsub -all -- \\\} $i \\\\\} i
  regsub -all -- \\\{ $i \\\\\{ i
  return $i
}

proc statistics::round {num} {
  if {![string match "*.*" $num]} {
    return $num\.0
  }
  if {![regexp -- {^(\d+?)\.(\d+)$} $num -> primary secondary]} {
    error "syntax error in expression '$num'"
  }
  set secondary [expr round([string index $secondary 0].[string range $secondary 1 end])]
  return [expr {($secondary == 10) ? ($primary+1.0) : "$primary.$secondary"}]
}

statistics::load

putlog "Script loaded: Statistics by perpleXa"

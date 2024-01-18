########################################################################
#
#BlackScan 1.0 TCL
#
#A type of TCL that helps in removing the clones from a chan.The functions are :
# - a scan command ( .clonescan ) and the eggdrop will show the clones from the chan + host
# - a clone scan interval and you can chose the type of punishment : 
#First method - ban -
#The next Method - Op NOTICE -
#
#To activate type in DCC : .chanset #canal +clonescan
#                                         
#                 -= The Next Generation TCL =-
#                                            BLaCKShaDoW ProductionS
#######################################################################

#Here you can set the maximum number of clones per host.

set scn(maxclone) "3"

#Here you can set the time interval for clone scanning (minutes) 

set scn(time) "30"

#Here you can set the flags that can apply the command for scanning. ( .clonescan )

set scn(flags) "o|o"

#Set here "1" if you want on the time interval scan if the eggdrop finds clones
#to ban them.Or set here "0" and on the time interval scan if the eggdrop finds clones
#it will NOTICE TO OPS.

set scn(what) "1"

#If you set on scn(what) "1" set here the ban reason

set scn(reason) "This host %host% has to many clones on %chan%.For more information contact the Ops."

#If you set on scn(what) "1" set here the ban duration. (minutes)

set scn(btime) "5"

#######################################################################
#
#                          Only god can judge me
#
#######################################################################

bind pub $scn(flags) .clonescan scanner
setudef flag clonescan

if {![info exists clonescanner_running]} {
timer $scn(time) clonescanner
set clonescanner_running 1
}


proc scanner {nick uhost hand chan arg} {
global scn count
array set clones [list]
if {[channel get $chan clonescan]} {
putquick "PRIVMSG $chan :Scanez.."
foreach user [chanlist $chan] {
set host [string tolower [lindex [split [getchanhost $user $chan] @] 1]]
if {![string match "*.undernet.org*" $host]} {
if {!($scn(maxclone) >= "2")} { return 0 }
if {![info exists c($host:$chan)]} {
set c($host:$chan) 0
}
set c($host:$chan) [expr $c($host:$chan) +1]
lappend clones($user) $host
if {$c($host:$chan) >= $scn(maxclone)} {
foreach clon [lsort -unique [array names clones]] {
set hosts [string tolower [lindex [split [getchanhost $clon $chan] @] 1]]
if {$host == $hosts} {
lappend clona($host) [join $clon " , "]
} 
}
putserv "NOTICE $nick :Found $c($host:$chan) clones on $chan from host $host. The nicks are : [lsort -unique $clona($host)]" 
}
}
puthelp "NOTICE $nick :End of clones.." 
} 
}
}

proc clonescanner {} {
global scn botnick
foreach chan [channels] {
set replace(%chan%) $chan
if {[channel get $chan clonescan]} {
putlog "Scanez de clone pe $chan.."
foreach user [chanlist $chan] {
set host [string tolower [lindex [split [getchanhost $user $chan] @] 1]]
set replace(%host%) $host
if {![info exists c($host:$chan)]} {
set c($host:$chan) 0
}
array set clones [list]
if {![string match "*.undernet.org*" $host]} {
if {!($scn(maxclone) >= "2")} { return 0 }
set c($host:$chan) [expr $c($host:$chan) +1]
lappend clones($user) $host
if {$c($host:$chan) >= $scn(maxclone)} {
foreach clon [array names clones] {
set hosts [string tolower [lindex [split [getchanhost $clon $chan] @] 1]]
if {$host == $hosts} {
lappend clona($host) [join $clon " , "]
} 
}
if {$scn(what) == "0"} {
putserv "NOTICE @$chan :WARNING :Found $c($host:$chan) clones on $chan from host $host. The nicks are : [lsort -unique $clona($host)]"
}
if {$scn(what) == "1"} {
set banmask *!*@$host
set reason [string map [array get replace] $scn(reason)]
newchanban $chan $banmask $botnick $reason [expr $scn(btime)]
}
}
}
}
}
}
timer $scn(time) clonescanner
return 1
}



putlog "BlackScan 1.0 by BLaCKShaDoW Loaded"


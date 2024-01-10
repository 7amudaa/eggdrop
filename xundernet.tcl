## Xundernet is a script that alowed you to use public 
## X (undernet) commands!
## If you found bugs report them to egghead@abacho.de
## or you chan find me on irc , server undernet on chans
## like #eggdrop and #cine? with nick kurupt
## Special Thanx to mc_8 and the #eggdrop and slenox
## You must have the +x flag to use the script!


# Set what prefix you whant to use! Default is "!"
# you chan modify with "." "`"
set cmdpfix "!"

## BINDS
bind pub -|x ${cmdpfix}xautotopic pub:xautotopic
bind pub -|x ${cmdpfix}xdesc pub:xdesc
bind pub -|x ${cmdpfix}xurl pub:xurl
bind pub -|x ${cmdpfix}xadduser pub:xadduser
bind pub -|x ${cmdpfix}xremuser pub:xremuser
bind pub -|x ${cmdpfix}xclear pub:xclear
bind pub -|x ${cmdpfix}xvoice pub:xvoice
bind pub -|x ${cmdpfix}xdevoice pub:xdevoice
bind pub -|x ${cmdpfix}xop pub:xop
bind pub -|x ${cmdpfix}xdeop pub:xdeop
bind pub -|x ${cmdpfix}xkick pub:xkick
bind pub -|x ${cmdpfix}xban pub:xban
bind pub -|x ${cmdpfix}xunban pub:xunban
bind pub -|x ${cmdpfix}xsuspend pub:xsuspend
bind pub -|x ${cmdpfix}xunsuspend pub:xunsuspend
bind pub -|x ${cmdpfix}xtopic pub:xtopic

## Don't modify if you don't know what you do

# !xautotopic <on|off>
proc pub:xautotopic {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :set $chan autotopic $ar"
	putcmdlog "<<$nick>> !$hand! x autotopic $chan"
}


# !xdesc <text>
proc pub:xdesc {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :set $chan desc $ar"
	putcmdlog "<<$nick>> !$hand! x desc $chan"
}


# !xurl <url>
proc pub:xurl {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :set $chan url $ar"
	putcmdlog "<<$nick>> !$hand! x url $chan"
}


# !xadduser <user> <level>
proc pub:xadduser {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :adduser $chan $ar"
	putcmdlog "<<$nick>> !$hand! x adduser $chan"
}


# !xremuser <user>
proc pub:xremuser {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :remuser $chan $ar"
	putcmdlog "<<$nick>> !$hand! x remuser $chan"
}


# !xclear
proc pub:xclear {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :clearmode $chan"
	putcmdlog "<<$nick>> !$hand! x clear $chan"
}


# !xvoice <nick1> <nick2> .. <nickn>
proc pub:xvoice {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :voice $chan $ar"
	putcmdlog "<<$nick>> !$hand! x voice $chan"
}


# !xdevoice <nick1> <nick2> .. <nickn>
proc pub:xdevoice {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :devoice $chan $ar"
	putcmdlog "<<$nick>> !$hand! x devoice $chan"
}


# !xop <nick1> <nick2> .. <nickn>
proc pub:xop {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :op $chan $ar"
	putcmdlog "<<$nick>> !$hand! x op $chan"
}


# !xdeop <nick1> <nick2> .. <nickn>
proc pub:xdeop {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :deop $chan $ar"
	putcmdlog "<<$nick>> !$hand! x deop $chan"
}


# !xkick <nick> <reason>
proc pub:xkick {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :kick $chan $ar"
	putcmdlog "<<$nick>> !$hand! x kick $chan"
}


# !xban <nick/host> <duration> <reason>
proc pub:xban {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :ban $chan $ar"
	putcmdlog "<<$nick>> !$hand! x ban $chan"
}


# !xunban <mask>
proc pub:xunban {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :unban $chan $ar"
	putcmdlog "<<$nick>> !$hand! x unban $chan"
}


# !xsuspend <user> <duration>
proc pub:xsuspend {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :suspend $chan $ar"
	putcmdlog "<<$nick>> !$hand! x suspend $chan"
}


# !xunsuspend <user>
proc pub:xunsuspend {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :unsuspend $chan $ar"
	putcmdlog "<<$nick>> !$hand! x unsusped $chan"
}


# !xtopic <topic>
proc pub:xtopic {nick uhost hand chan ar} {
	global botnick
      putserv "PRIVMSG X :topic $chan $ar"
	putcmdlog "<<$nick>> !$hand! x topic $chan"
}

putlog "Xundernet by kurupthas been loaded."

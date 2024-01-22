# TCL Debugging script
#
# Lets you run commands on your bot on the channel
# and also trace error messages
# 
# Command	Type	Description
# !tcl		msg		run a TCL command and print the result in a query
# !exec		msg		run a shell command and print the result in a query
# !error	msg		prints the last errormessage in a query
# !tcl		pub		run a TCL command and print the result on a channel 
# !exec		pub		run a shell command and print the result on a channel
# !error	pub		prints the last errormessage on a channel
# .exec		dcc		run a shell command and print the result on the partyline
# .error	dcc		prints the last errormessage on the partyline
# .tclset	dcc		toggles the .tcl partyline command on or off. Usage: .tclset <enable/disable>
# .tclemu	dcc		emulates the .tcl partyline command
#
# New version by Joose
# [joose Ã¤t joose piste biz]
# http://code.joose.biz/eggdrop/
#
# Original code by Never & c*bex

# - Settings - #

# Set the suffix for the commands (e.g "%tcl")
# Default: "!"
set {tcldebug:suffix} "!"

# Set the userflag for the commands
# Default "n" (owner)
set {tcldebug:flag} "n"

# - No need to change after this - #

bind msg ${tcldebug:flag} "${tcldebug:suffix}tcl" tcldebug:tcl
bind pub ${tcldebug:flag} "${tcldebug:suffix}tcl" tcldebug:tcl
bind pub ${tcldebug:flag} "$::nick" 	tcldebug:tcl
bind pub ${tcldebug:flag} "$::altnick" tcldebug:tcl
bind pub ${tcldebug:flag} "all" tcldebug:tcl


bind msg ${tcldebug:flag} "${tcldebug:suffix}exec" tcldebug:exec
bind pub ${tcldebug:flag} "${tcldebug:suffix}exec" tcldebug:exec

bind msg ${tcldebug:flag} "${tcldebug:suffix}error" tcldebug:error
bind pub ${tcldebug:flag} "${tcldebug:suffix}error" tcldebug:error

bind dcc ${tcldebug:flag} "exec" tcldebug:execdcc
bind dcc ${tcldebug:flag} "error" tcldebug:errordcc
bind dcc ${tcldebug:flag} "tclset" tcldebug:tclset
bind dcc ${tcldebug:flag} "tclemu" tcldebug:tclemu

proc tcldebug:tcl {nick host hand chan args} {
   set args [lindex $args 0]
   putcmdlog "%tcl: $nick $host $hand $chan $args"
   set start [clock clicks]
   set errnum [catch {eval $args} error]
   set end [clock clicks]
   if {$error==""} {set error "<empty string>"}
   switch -- $errnum {
	  0 {if {$error=="<empty string>"} {set error "OK"} {set error "OK: $error"}}
	  4 {set error "continue: $error"}
	  3 {set error "break: $error"}
	  2 {set error "return: $error"}
	  1 {set error "error: $error"}
	  default {set error "$errnum: $error"}
   }
   set error "$error - [expr ($end-$start)/1000.0] ms"
   foreach row [split $error "\n"] { putserv "PRIVMSG $chan :$row" }
}

proc tcldebug:exec {nick host hand chan args} {
   set args "exec [lindex $args 0]"
   set errnum [catch {eval $args} error]
   if {$error==""} {set error "<$errnum>"}
   if {$errnum!=0} {set error "$errnum - $error"}
   foreach row [split $error "\n"] { putserv "PRIVMSG $chan :$row" }
}

proc tcldebug:error {nick host hand chan args} {
   foreach row [split $::errorInfo \n] {
	  puthelp "PRIVMSG $chan :$row"
   }
}

proc tcldebug:execdcc { hand idx args } {
   set args "exec [lindex $args 0]"
   set errnum [catch {eval $args} error]
   if {$error==""} {set error "<$errnum>"}
   if {$errnum!=0} {set error "$errnum - $error"}
   foreach row [split $error "\n"] { putdcc $idx $row }
}

proc tcldebug:errordcc { hand idx args } {
	putdcc $idx "TCL debug:"
	putdcc $idx "-----------------------------------"
	foreach line [split $::errorInfo \n] {
		putdcc $idx "$line"
	}
	putdcc $idx "-----------------------------------"
}

proc tcldebug:tclset { hand idx args } {
	switch -- $args {
		"enable" {
			bind dcc n tcl *dcc:tcl
			putdcc $idx ".tcl enabled"
		}
		"disable" {
			unbind dcc n tcl *dcc:tcl
			putdcc $idx ".tcl disabled"
		}
		default {
			putdcc $idx "Usage: .tclset <enable/disable>"
		}
	}
}

proc tcldebug:tclemu { hand idx args } {
   set args [lindex $args 0]
   putcmdlog ".tclemu: $hand"
   set start [clock clicks]
   set errnum [catch {eval $args} error]
   set end [clock clicks]
   if {$error==""} {set error "<empty string>"}
   switch -- $errnum {
	  0 {if {$error=="<empty string>"} {set error "OK"} {set error "OK: $error"}}
	  4 {set error "continue: $error"}
	  3 {set error "break: $error"}
	  2 {set error "return: $error"}
	  1 {set error "error: $error"}
	  default {set error "$errnum: $error"}
   }
   set error "$error - [expr ($end-$start)/1000.0] ms"
   foreach row [split $error "\n"] { putdcc $idx $row }
}

putlog "[file tail [info script]] v. 2.5 by Joose loaded"

putlog "Unload TCL by terroris loaded"
# Script: unloadtcl.tcl
# Version: 1.2
# Author: Wingman <Wingman@WINGDesign.de> - Edit by MoBi 
# Description: This scripts allows you to load/unload tcl scripts via dcc
#------------------------------------------------------------------------
# PARTYLINE
# DCC Commands:
# .loadtcl <scriptname>
# .unloadtcl <scriptname>
# .viewtcls <loaded/all>
#------------------------------------------------------------------------
# Settings:
# 0 = no rehash/restart, 1 = rehash, 2 = restart
#------------------------------------------------------------------------

set ul(refresh) 1


set ul(dir) "scripts"


set ul(pattern) "*.tcl"




# Bindings:


bind dcc n unloadtcl dcc:unloadtcl


bind dcc n loadtcl dcc:loadtcl


bind dcc n viewtcls dcc:viewtcls 




# Procedures - You don't have to edit anything below.



proc ul:get_scripts {} {

  global config

  set loaded_scripts ""

  set file [open $config r]

  while {![eof $file]} {

    set line [gets $file]

    if {[string match "source*" $line]} {

      set script "[string range $line 15 end]"

      if {[string match "/" $script]} {

        set script [lindex [split $script /] [incr [llength [split $script /]] -1]]

        set path [string range $line 0 [string length $script]]

      }

      append loaded_scripts "$script "

    }

  }

  close $file

  return $loaded_scripts

}


proc dcc:loadtcl { hand idx arg } {

  global config ul

  if {[llength $arg] < 1} {

    putdcc $idx "(h4C) Usage: .loadtcl <scriptname>"

    return

  } 

  if {![file exists scripts/$arg]} {

    putdcc $idx "(h4C) Can't find tcl $arg."

    return

  }

  if {[lsearch "[ul:get_scripts]" $arg] != -1} {

    putdcc $idx "(h4C) tCl script already loaded: $arg"

    return

  }

  set file [open $config a+]

  puts $file "source scripts/$arg"

  close $file

  putdcc $idx "(h4C) Done. $arg successfully loaded."

  if {$ul(refresh) == 1} { 

    rehash

  } elseif {$ul(refresh) == 2} {

    restart

  } {

    putdcc $idx "(h4C) Now do a .rehash or .restart."

  }

  return 1

}


proc dcc:unloadtcl { hand idx arg } {

  global config ul 

  if {[llength $arg] < 1} {

    putdcc $idx "(h4C) Usage: .unloadtcl <scriptname>"

    putdcc $idx "       try '.viewtcls loaded' for a list of loaded scripts"

    return 

  }

  if {![file exists scripts/$arg]} {

    putdcc $idx "(h4C) Can't find tCl: $arg."

    return

  }

  set file [open $config r]

  while {![eof $file]} {

    set line [gets $file]

    if {![string match "source scripts/$arg *" $line] && ![string match "source scripts/$arg" $line]} {

      lappend content $line

    } {

      set foo 1

    }

  }

  close $file

  if {![info exists foo]} {

    putdcc $idx "(h4C) Can't find loaded tCl: $arg."

    return

  }

  set file [open $config w]

  foreach line $content { puts $file $line }

  close $file

  set ubc_success 0

  set ubc_failed 0

  set proc_success 0

  set proc_failed 0

  set file [open scripts/$arg r]

  while {![eof $file]} {

    set line [gets $file]

    if {([string match "* bind *" $line] || [string match "bind *" $line]) && ![string match "*#*" $line]} {

      set foo1  [lindex $line 1]

      if {[string match "*\$*" $foo1]} {

        set varname [lindex [split $foo1 \$] 1]

	if {[string match "*(*" $varname]} {

	  global [lindex [split $varname (] 0]

	} {

	  global $varname

	}

	set foo1 [set $varname]

      }

      set foo2 [lindex $line 2]

     if {[string match "*\$*" $foo2]} {

	if {[llength [split $foo2 |]] == 2} {

	  set gflag [lindex [split $foo2 |] 0]

	  set cflag [lindex [split $foo2 |] 1]

	  if {[string index $gflag 0] == "\$"} {

 	    global [string trimleft $gflag $]

	    set foo2 "[set [string trimleft $gflag $]]"

	  } {

	    set foo2 "$gflag"

	  }

	  if {[string index $cflag 1] == "\$"} {

	    global [string trimleft $cflag $]

	    append foo2 "|[set [string trimleft $cflag $]]"

	  } {

	    append foo2 "|$cflag"

	  }

	} elseif {[llength [split $foo2 &]] == 2} {

          set gflag [lindex [split $foo2 &] 0]

          set cflag [lindex [split $foo2 &] 1]

          if {[string index $gflag 0] == "\$"} {

            global [string trimleft $gflag $]

            set foo2 "[set [string trimleft $gflag $]]"

          } {

            set foo2 "$gflag"

          }

          if {[string index $cflag 1] == "\$"} {

            global [string trimleft $cflag $]

            append foo2 "&[set [string trimleft $cflag $]]"

          } {

            append foo2 "&$cflag"

          }

	} else {

          set varname [lindex [split $foo2 "\$"] 1]

          if {[string match "*(*" $varname]} {

            global [lindex [split $varname (] 0]

          } {

            global $varname

	  }

	  set foo2 [set $varname]

	}

      }

      set foo3 [lindex $line 3]

      if {[string match "*\$*" $foo3]} {

        set varname [lindex [split $foo3 \$] 1]

        if {[string match "*(*" $varname]} {

	  global [lindex [split $varname (] 0]

	} {

          global $varname

	}

	set foo3 [set $varname]

      }

      set foo4 [lindex $line 4]

      catch { unbind $foo1 $foo2 $foo3 $foo4 } error

      if {[string match "TCL error:*" $error]} {

        putdcc $idx "(h4C) *** error, while executing: unbind $foo1 $foo2 $foo3 $foo4"

	putdcc $idx "     msg: $error"

	incr ubc_failed

      } {

        incr ubc_success

      }

    }

    if {[string match "*proc *\{*\}*\{*" $line]} {

      set procname [lindex [lindex [split $line \{] 0] 1]

      catch { rename $procname "" } error

      if {[string match "TCL error:*" $error]} {

        putdcc $idx "(h4C) *** error while executing: rename $procname \"\""

	putdcc $idx "     msg: $error"

	incr proc_failed

      } {

        incr proc_success

      }

    }

  }

  close $file

  putdcc $idx "(h4C) All Done. Showing report:"

  putdcc $idx "   Unbinded $ubc_success commands."

  if {$ubc_failed > 0} {

    putdcc $idx "   * failed: $ubc_failed commands."

  }

  putdcc $idx "   Deleted $proc_success procedures."

  if {$proc_failed > 0} {

    putdcc $idx "   * failed: $proc_failed procedures."

  }

  if {$ul(refresh) == 1} {

    rehash

  } elseif {$ul(refresh) == 2} {

    restart

  } {

    putdcc $idx "(h4C) I recommend to do an rehash or better a .restart !"

  }

  return 1

}


proc dcc:viewtcls { hand idx arg } {

  global ul

  set loaded_scripts [ul:get_scripts]

  if {[string tolower $arg] == "loaded"} {  

    putlog "#$hand# viewtcls $arg"

    if {![info exists loaded_scripts]} {

      putdcc $idx "(h4C) No tcls loaded."

    } {

      putdcc $idx "(h4C) List of loaded tcls:"

      foreach script $loaded_scripts {

        putdcc $idx "  $script"

      }

    }

    return

  } elseif {[string tolower $arg] == "all"} {

    catch { glob $ul(dir)/$ul(pattern) } tclfiles

    if {[lrange "$tclfiles" 0 4] == "no files matched glob pattern"} {

      putdcc $idx "(h4C) Can't find any tcl ($ul(pattern)) script in $ul(dir)."

      return 1

    }

    foreach script $tclfiles {

      if {[lsearch -exact "$loaded_scripts" [string range $script [expr [string length $ul(dir)]+1] end]] == -1} {

        putdcc $idx "   [string range $script [expr [string length $ul(dir)]+1] end]"

      } {

        putdcc $idx "   [string range $script [expr [string length $ul(dir)]+1] end] (loaded)"
      }

    }

    return 1

  }

putdcc $idx "(h4C) Usage: .viewtcls <loaded/all>"

return

}


putlog "(h4C) unload.t4Cl LOADED!"



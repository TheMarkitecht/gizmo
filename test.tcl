#  gizmo
#  Copyright 2020 Mark Hubbard, a.k.a. "TheMarkitecht"
#  http://www.TheMarkitecht.com
#
#  Project home:  http://github.com/TheMarkitecht/gizmo
#  gizmo is a GNOME / GTK+ 3 windowing shell for Jim Tcl (http://jim.tcl.tk/)
#  gizmo helps you quickly develop modern cross-platform GUI apps in Tcl.
#
#  This file is part of gizmo.
#
#  gizmo is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  gizmo is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with gizmo.  If not, see <https://www.gnu.org/licenses/>.



proc assert {exp} {
    set truth [uplevel 1 [list expr $exp]]
    if { ! $truth} {
        error "ASSERT FAILED: $exp"
    }
}

proc bench {label  reps  script} {
    puts "$label:  reps=$reps"
    flush stdout
    set beginMs [clock milliseconds]
    uplevel 1 loop attempt 0 $reps \{ $script \}
    set elapseMs $([clock milliseconds] - $beginMs)
    set eachUs $(double($elapseMs) / double($reps) * 1000.0)
    puts [format "    time=%0.3fs  each=%0.1fus" $(double($elapseMs) / 1000.0) $eachUs]
    flush stdout
}

# required packages.
puts paths=$::auto_path
package require gizmo

# script interpreter support.
alias  ::get  set ;# allows "get" as an alternative to the one-argument "set", with much clearer intent.

# command line.
#lassign $::argv  ::metaAction  ::giSpace  ::giSpaceVersion  namePattern
#if {$namePattern eq {}} {set namePattern * }
set ::metaAction refreshMeta

# globals
set ::appDir [file join [pwd] [file dirname [info script]]]

# test a glib call.
#todo: reinstate
#::g::assertion_message  one  two  3  four  five
#puts call-Done


# test a gio class.
::gi::loadSpace  $::metaAction  Gio  2.0  libgio-2.0.so
# puts [join [lsort [info commands ::gio::*]] \n]
set complr [gio.FilenameCompleter new]
puts class=[$complr classname]
puts methods=[$complr methods]
#todo: call a method

exit 0

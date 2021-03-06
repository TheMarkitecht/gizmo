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
#lassign $::argv  ::metaAction  testName
set ::metaAction refreshMeta

# globals
set ::appDir [file join [pwd] [file dirname [info script]]]

# test a glib call.
#todo: reinstate
#::g::assertion_message  one  two  3  four  five
#puts call-Done

# load GI namespaces required for this app.
::gi::loadSpace  $::metaAction  GLib  2.0  libglib-2.0.so
set ::g::ignoreNames [list  g_strv_get_type  g_variant_get_gtype] ;#todo: move to g.tcl.
::gi::declareAllInfos  GLib  ;#todo: move to g.tcl.
::gi::loadSpace  $::metaAction  GObject  2.0  libgobject-2.0.so
set ::gobject::ignoreNames [list  g_signal_set_va_marshaller] ;#todo: move to gobject.tcl.
::gi::declareAllInfos  GObject  ;#todo: move to gobject.tcl.

# test a class:  gio.Credentials
::gi::loadSpace  $::metaAction  Gio   2.0  libgio-2.0.so
# puts [join [lsort [info commands ::gio::*]] \n]
set ::gio::ignoreNames [list g_io_module_query] ;#todo: move to gio.tcl.
::gi::declareAllInfos  Gio  ;#todo: move to gio.tcl.
set creds [gio.Credentials new]
puts class=[$creds classname]
puts vars=[$creds vars]
puts methods=[$creds methods]
set c [$creds  to_string]
puts creds=$c
assert {[regexp -nocase {\<pid=(\d+)\>} $c junk pid]}
puts pid=$pid
assert {int($pid) > 1}

#todo: test parameter passing to methods

exit 0

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

set ::appDir [file join [pwd] [file dirname [info script]]]

puts paths=$::auto_path

package require dlr

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

# depends on a libgirepository-1.0.so symlink in the appDir.
#todo: loadLib with an empty path to indicate one already linked.  use that lib here instead of the extra dyn loaded one.
::dlr::loadLib  refreshMeta  gi  ./libgirepository-1.0.so
puts Load-Done

set repoP [::dlr::lib::gi::g_irepository_get_default::call]

set err 0
#todo: upgrade from 2.0
set tlbP [::dlr::lib::gi::g_irepository_require::call  $repoP  GLib  2.0  0  err]
puts err=$err
puts [format tlbP=$::dlr::ptrFmt $tlbP]

set fnInfoP [dlr::native::giFindFunction  $repoP  GLib  assertion_message]
puts [format fnInfoP=$::dlr::ptrFmt $fnInfoP]

puts nArgs=[::dlr::lib::gi::g_callable_info_get_n_args::call $fnInfoP]
exit 0

# load the library binding for testLib.
::dlr::loadLib  refreshMeta  testLib  [file join $::appDir .. dlr testLib-src testLib.so]
puts Load-Done

# add a bogus function that we'll hijack for GI.
::dlr::declaregiCallToNative  applyScript  testLib  {void}  assertGI  {
    {in     byPtr   ascii   a       asString}
    {in     byPtr   ascii   b       asString}
    {in     byVal   int     line    asInt}
    {in     byPtr   ascii   c       asString}
    {in     byPtr   ascii   d       asString}
}
puts Declare-Done

# puts [join [lsort [info commands ::dlr::lib::testLib::*]] \n]
::dlr::lib::testLib::assertGI::call  one  two  3  four  five
puts call-Done

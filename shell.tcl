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

# required packages.
puts paths=$::auto_path
package require gizmo

# command line.
#lassign $::argv  ::metaAction  testName
set ::metaAction refreshMeta

# load GI namespaces required for this app.
::gi::loadSpace  $::metaAction  GLib  2.0  libglib-2.0.so
::gi::declareAllInfos  GLib  ;#todo: move to g.tcl.
::gi::loadSpace  $::metaAction  GObject  2.0  libgobject-2.0.so
::gi::declareAllInfos  GObject  ;#todo: move to gobject.tcl.
::gi::loadSpace  $::metaAction  Gio   2.0  libgio-2.0.so
set ::gio::ignoreNames [list g_io_module_query] ;#todo: move to gio.tcl.
::gi::declareAllInfos  Gio  ;#todo: move to gio.tcl.

# REPL loop.
while {1} {
    puts -nonewline "\n> "
    set ln [gets stdin]
    try {
        puts [eval $ln]
    } on error {msg opts} {
        puts "Error: $msg"
    }
}

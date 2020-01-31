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

proc loadSpace {giSpace  giSpaceVersion} {
    set ::giSpace  $giSpace
    set ::giSpaceVersion  $giSpaceVersion
    set errP 0
    set tlbP [::gi::g_irepository_require  $::gi::repoP  $giSpace  $giSpaceVersion  0  errP]
    ::g::checkGError $errP
    assert {$tlbP != 0}
    puts "tlbP=$tlbP  space=$giSpace"
}

proc allInfos {} {
    puts "allInfos  space=$::giSpace"
    set nInfos [::gi::g_irepository_get_n_infos  $::gi::repoP  $::giSpace]
    set ptrs [list]
    loop i 0 $nInfos {
        lappend ptrs [::gi::g_irepository_get_info  $::gi::repoP  $::giSpace  $i]
    }
    return $ptrs
}

# required packages.
package require dlr
if { ! $::dlr::giEnabled} {
    error "dlr library was compiled with no GI support."
}
::dlr::loadLib  keepMeta  gi  libgirepository-1.0.so

# globals
set ::giSpace  {}
set ::giSpaceVersion  {}

# parse command line
if {$::argc == 2} {
    loadSpace  {*}$::argv
}

# dump all available infos
set name {}
set value {}
foreach infoP [allInfos] {
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $infoP]]
    puts [format  %10s:%s  $tn  [::gi::g_base_info_get_name $infoP]]

    set iterP [::dlr::lib::gi::struct::GIAttributeIter::packNew  iter]
    while {[::gi::g_base_info_iterate_attributes  $infoP  $iterP  name  value]} {
        puts "    attr: $name = $value"
    }
}

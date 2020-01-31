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

alias dump-function dump-callable

alias dump-signal dump-callable

proc dump-callable {infoP} {
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $infoP]]
    puts [format  {%10s: %s}  $tn  [::gi::g_base_info_get_name $infoP]]

    # return
    set rTypeP [::gi::g_callable_info_get_return_type $infoP]
    set tag [::gi::g_type_info_get_tag $rTypeP]
    puts [format  {%14s: %s}  returnType  $tag]
    ::gi::g_base_info_unref $rTypeP

    # parms
    set nArgs [::gi::g_callable_info_get_n_args $infoP]
    loop i 0 $nArgs {
        set argP [::gi::g_callable_info_get_arg $infoP $i]
        set aTypeP [::gi::g_arg_info_get_type $argP]
        set tag [::gi::g_type_info_get_tag $aTypeP]
        puts [format  {%18s: %s}  argType  $tag]
        ::gi::g_base_info_unref $argP
    }
}

proc dump-interface {infoP} {
    # signals
    set nSigs [::gi::g_interface_info_get_n_signals $infoP]
    loop i 0 $nSigs {
        set sigP [::gi::g_interface_info_get_signal $infoP $i]
        dump-signal $sigP
        ::gi::g_base_info_unref $sigP
    }
}

# this really should be dump-class, but GNOME calls it object.
proc dump-object {infoP} {
    # signals
    set nSigs [::gi::g_object_info_get_n_signals $infoP]
    loop i 0 $nSigs {
        set sigP [::gi::g_object_info_get_signal $infoP $i]
        dump-signal $sigP
        ::gi::g_base_info_unref $sigP
    }
}

proc dump-info {infoP} {
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $infoP]]
    puts [format  {%10s: %s}  $tn  [::gi::g_base_info_get_name $infoP]]

    # arbitrary string attributes.  evidently uncommon.
    set name {}
    set value {}
    set iterP [::dlr::lib::gi::struct::GIAttributeIter::packNew  iter]
    while {[::gi::g_base_info_iterate_attributes  $infoP  $iterP  name  value]} {
        puts [format  {%14s: %s}  "attr: $name" $value]
    }

    # info-type-specific stuff.
    if {[exists -command dump-$tn]} {
        dump-$tn  $infoP
    }
}

# command line.
lassign $::argv  ::metaAction  ::giSpace  ::giSpaceVersion  namePattern
if {$namePattern eq {}} {set namePattern * }

# required packages.
package require dlr
if { ! $::dlr::giEnabled} {
    error "dlr library was compiled with no GI support."
}
::dlr::loadLib  $::metaAction  gi  libgirepository-1.0.so
loadSpace  $::giSpace  $::giSpaceVersion

# globals

# dump all available infos
set all [allInfos]
puts "[llength $all] total infos"
foreach infoP $all {
    set name [::gi::g_base_info_get_name $infoP]
    if {[string match -nocase $namePattern $name]} {
        dump-info $infoP
    }
}

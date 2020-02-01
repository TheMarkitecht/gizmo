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

proc rootInfos {} {
    puts "rootInfos  space=$::giSpace"
    set nInfos [::gi::g_irepository_get_n_infos  $::gi::repoP  $::giSpace]
    set ptrs [list]
    loop i 0 $nInfos {
        lappend ptrs [::gi::g_irepository_get_info  $::gi::repoP  $::giSpace  $i]
    }
    return $ptrs
}

alias dump-function dump-callable

alias dump-signal dump-callable

proc dump-callable {label  indent  infoP} {
    # return value.
    dumpTypeInfoUnref  return  $indent  [::gi::g_callable_info_get_return_type $infoP]

    # parms
    set nArgs [::gi::g_callable_info_get_n_args $infoP]
    loop i 0 $nArgs {
        dumpInfoUnref  {}  $indent  [::gi::g_callable_info_get_arg $infoP $i]
    }
}

proc dump-arg {label  indent  infoP} {
    dumpTypeInfoUnref  {}  $indent  [::gi::g_arg_info_get_type $infoP]
}

proc dump-interface {label  indent  infoP} {
    # signals
    set nSigs [::gi::g_interface_info_get_n_signals $infoP]
    loop i 0 $nSigs {
        dumpInfoUnref  {}  $indent  [::gi::g_interface_info_get_signal $infoP $i]
    }
}

# this really should be dump-class, but GNOME calls it object.
proc dump-object {label  indent  infoP} {
    # signals
    set nSigs [::gi::g_object_info_get_n_signals $infoP]
    loop i 0 $nSigs {
        dumpInfoUnref  {}  $indent  [::gi::g_object_info_get_signal $infoP $i]
    }
}

# main dumper for all BaseInfo's.  all subtypes of those come through here,
# except GITypeInfo.  see dumpTypeInfo.
proc dumpInfo {label  indent  infoP} {
    if {$label ne {}} {append label { : }}
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $infoP]]
    puts -nonewline "$indent${label}<${tn}> : "
    # this next function crashes on certain structs.
    flush stdout
    puts [::gi::g_base_info_get_name $infoP]

    # arbitrary string attributes.  evidently uncommon.
    set name {}
    set value {}
    set header "$indent    attributes\n"
    set iterP [::dlr::lib::gi::struct::GIAttributeIter::packNew  iter]
    while {[::gi::g_base_info_iterate_attributes  $infoP  $iterP  name  value]} {
        puts -nonewline $header
        set header {}
        puts "$indent        $name : $value"
    }

    # info-type-specific stuff.
    if {[exists -command dump-$tn]} {
        dump-$tn  {}  "$indent    "  $infoP
    }
}

proc dumpInfoUnref {label  indent  ptr} {
    dumpInfo  $label  $indent  $ptr
    ::gi::g_base_info_unref $ptr
}

proc dumpTypeInfoUnref {label  indent  typeInfoP} {
    dumpTypeInfo  $label  $indent  $typeInfoP
    ::gi::g_base_info_unref $typeInfoP
}

proc dumpTypeInfo {label  indent  typeInfoP} {
    # typeInfoP points to a GITypeInfo.  that struct is a subtype of GIBaseInfo.
    # but it has no additional members of its own.
    # but g_base_info_get_name fails on it.

    # this dumper shows a header like the root dumper dumpInfo,
    # because typeInfo's don't appear in rootInfos.  their identifying header
    # hasn't already been printed.
    if {$label ne {}} {append label { : }}
    set tag [::gi::g_type_info_get_tag $typeInfoP]
    puts "$indent${label}typeInfo tag $tag : [::gi::g_info_type_to_string $tag]"
    #todo: g_info_type_to_string gives the wrong names.
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
set roots [rootInfos]
puts "[llength $roots] total root infos"
foreach infoP $roots {
    set name [::gi::g_base_info_get_name $infoP]
    if {[string match -nocase $namePattern $name]} {
        dumpInfo  {}  {}  $infoP
    }
}

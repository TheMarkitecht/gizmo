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
    set tlbP [::gi::loadSpace  $::metaAction  $giSpace  $giSpaceVersion]
    puts "space=$giSpace  v=$giSpaceVersion  tlbP=[format $::dlr::ptrFmt $tlbP]"
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

proc dump-function {label  indent  infoP} {
    puts "${indent}C-symbol: [::gi::g_function_info_get_symbol $infoP]"
    dump-callable  $label  $indent  $infoP
}

alias dump-signal dump-callable

proc dump-callable {label  indent  infoP} {
    # return value.
    dumpTypeInfoUnref  return  $indent  [::gi::g_callable_info_get_return_type $infoP]

    # parms
    set nArgs [::gi::g_callable_info_get_n_args $infoP]
    loop i 0 $nArgs {
        dumpInfoUnref  parm  $indent  [::gi::g_callable_info_get_arg $infoP $i]
    }
}

proc dump-arg {label  indent  infoP} {
    set dir [::gi::g_arg_info_get_direction $infoP]
    puts "${indent}dir: $::gi::GIDirection::toName($dir)"

    dumpTypeInfoUnref  type  $indent  [::gi::g_arg_info_get_type $infoP]
}

proc dump-interface {label  indent  infoP} {
    # methods
    set nMeth [::gi::g_interface_info_get_n_methods $infoP]
    loop i 0 $nMeth {
        dumpInfoUnref  method  $indent  [::gi::g_interface_info_get_method $infoP $i]
    }

    # signals
    set nSigs [::gi::g_interface_info_get_n_signals $infoP]
    loop i 0 $nSigs {
        dumpInfoUnref  signal  $indent  [::gi::g_interface_info_get_signal $infoP $i]
    }
}

# this really should be dump-class, but GNOME calls it object.
proc dump-object {label  indent  infoP} {
    # methods
    set nMeth [::gi::g_object_info_get_n_methods $infoP]
    loop i 0 $nMeth {
        dumpInfoUnref  method  $indent  [::gi::g_object_info_get_method $infoP $i]
    }

    # signals
    set nSigs [::gi::g_object_info_get_n_signals $infoP]
    loop i 0 $nSigs {
        dumpInfoUnref  signal  $indent  [::gi::g_object_info_get_signal $infoP $i]
    }
}

# main dumper for all BaseInfo's.  all subtypes of those come through here,
# except GITypeInfo.  see dumpTypeInfo.
proc dumpInfo {label  indent  infoP} {
    if {$label ne {}} {append label { : }}
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $infoP]]
    puts "$indent${label}<${tn}> : [::gi::g_base_info_get_name $infoP]"

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
    #puts "$indent${label}typeInfo tag $tag : [::gi::g_info_type_to_string $tag]"
    #todo: g_info_type_to_string gives the wrong names.
    set dTyp  $( [dict exists $::gi::GITypeTag::toDlrType $tag]  ?  $::gi::GITypeTag::toDlrType($tag)  :  {} )
    puts "$indent${label}typeInfo tag $tag : $::gi::GITypeTag::toName($tag) : $dTyp"

    #todo: param_type offers no upper limit to its index?  and, turns out, it's a bottomless recursion too.
    #loop i 0 1 {
        #dumpTypeInfoUnref  paramType  "$indent    "  \
            #[::gi::g_type_info_get_param_type $typeInfoP $i]
    #}

    if {[::gi::g_type_info_is_pointer $typeInfoP]} {
        puts "$indent    is pointer."
    }

    # this is actually the length of each tuple within the array.
    set len [::gi::g_type_info_get_array_length $typeInfoP]
    if {$len >= 0} {
        puts "$indent    tuple length $len"
    }

    if {$tag == $::gi::GITypeTag::toValue(INTERFACE)} {
        set ifcP  [::gi::g_type_info_get_interface $typeInfoP]
        set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $ifcP]]
        puts "$indent    <${tn}> : [::gi::g_base_info_get_name $ifcP]"
        ::gi::g_base_info_unref $ifcP
    }
}

# command line.
lassign $::argv  ::metaAction  ::giSpace  ::giSpaceVersion  namePattern
if {$namePattern eq {}} {set namePattern * }

# required packages.
package require dlr
# this code borrows from initgizmo.tcl to initialize gi, because inspector is made to run
# in jimsh, not gizmo.
if { ! $::dlr::giEnabled} {
    error "dlr library was compiled with no GI support."
}
::dlr::loadLib  $::metaAction  gi  libgirepository-1.0.so

# script interpreter support.
alias  ::get  set ;# allows "get" as an alternative to the one-argument "set", with much clearer intent.

# globals

# dump all available infos
loadSpace  $::giSpace  $::giSpaceVersion
set roots [rootInfos]
puts "[llength $roots] total root infos"
foreach infoP $roots {
    set name [::gi::g_base_info_get_name $infoP]
    if {[string match -nocase $namePattern $name]} {
        dumpInfo  {}  {}  $infoP
    }
}

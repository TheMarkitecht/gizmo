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

proc dget {dicV args} {
    set keys [lrange $args 0 end-1]
    set default [lindex $args end]
    return $( [dict exists $dicV {*}$keys] ? [dict get $dicV {*}$keys] : $default )
}

proc out {txt} {
    puts [format {%4d: %s} $::lineNum $txt]
    incr ::lineNum
}

proc outPartial {txt} {
    puts -nonewline $txt
}

class GroupRecord {cnt 0 see {}}
GroupRecord method incr {} {incr cnt}
GroupRecord method see {lineNum} {set see $lineNum}

class GroupKey {tag {} isP {} ifcType {} ifcName {} key {}}
proc "GroupKey fromType" {tag isP ifcType ifcName} {
    # 'key' is the identifying string for use as a key to ::tot dict.
    # ifcName is disregarded for grouping right now.
    set gk [GroupKey new [list tag $tag isP $isP ifcType $ifcType \
        ifcName $ifcName key [list $tag $isP $ifcType]]]
    return $gk
}
proc "GroupKey fromKey" {keyStr} {
    # 'key' is the identifying string for use as a key to ::tot dict.
    # ifcName is disregarded for grouping right now.
    lassign $keyStr tag isP ifcType
    GroupKey new [list tag $tag isP $isP ifcType $ifcType ifcName {} key $keyStr]
}
GroupKey method tagName {} {return $::gi::GITypeTag::toName($tag)}
GroupKey method dlrType {} {dget $::gi::GITypeTag::toDlrType $tag unmapped}
GroupKey method atRisk {} { return $( [$self dlrType] eq {unmapped} && ! $isP ) }
GroupKey method appearsOn {lineNum} {
    if {[dict exists $::tot $key]} {
        $::tot($key) incr
    } else {
        set ::tot($key)  [GroupRecord new {cnt 1}]
    }
    $::tot($key) see $lineNum
}
GroupKey method format {} {
    set grp $::tot($key)
    set pv $( $isP ? {ptr} : {} )
    set risk "$( [$self atRisk] ? {AT RISK } : {} )see [$grp get see]"
    return [format "    %5d %16s %3s %16s %-26s %-26s %s"  \
        [$grp get cnt]  [$self tagName]  $pv  $ifcType  $ifcName  [$self dlrType]  $risk ]
}

proc compareCnt {ka kb} {
    set a [$::tot($ka) get cnt]
    set b [$::tot($kb) get cnt]
    if {$a < $b} {return -1}
    if {$a > $b} {return 1}
    return 0
}

proc reportGroups {} {
    # show total occurrences of argument types.
    set flat [lsort -command compareCnt -decreasing [dict keys $::tot]]
    out Totals:
    foreach keyStr $flat {
        puts [[GroupKey fromKey $keyStr] format]
    }
}

proc loadSpace {giSpace  giSpaceVersion  soPath} {
    set ::giSpace  $giSpace
    set ::giSpaceVersion  $giSpaceVersion
    set tlbP [::gi::loadSpace  $::metaAction  $giSpace  $giSpaceVersion  $soPath]
    out "space=$giSpace  v=$giSpaceVersion  tlbP=[format $::dlr::ptrFmt $tlbP]"
}

proc rootInfos {} {
    out "rootInfos  space=$::giSpace"
    set nInfos [::gi::g_irepository_get_n_infos  $::gi::repoP  $::giSpace]
    set ptrs [list]
    loop i 0 $nInfos {
        lappend ptrs [::gi::g_irepository_get_info  $::gi::repoP  $::giSpace  $i]
    }
    return $ptrs
}

proc dump-struct {label  indent  infoP} {
    out "${indent}size: [::gi::g_struct_info_get_size $infoP]"
    set nMems [::gi::g_struct_info_get_n_fields $infoP]
    loop i 0 $nMems {
        set mInfoP [::gi::g_struct_info_get_field $infoP $i]
        out "${indent}member: [::gi::g_base_info_get_name $mInfoP]"
        out "${indent}    offset: [::gi::g_field_info_get_offset $mInfoP]"
        # size is not useful.  it's implied by the member's type.
        # that's probably why g_field_info_get_size always returns 0 ?
        #out "${indent}    size:   [::gi::g_field_info_get_size $mInfoP]"
        dumpTypeInfoUnref  type  "$indent    "  [::gi::g_field_info_get_type $mInfoP]
        ::gi::g_base_info_unref $mInfoP
    }
    ::gi::g_base_info_unref $infoP
}

proc dump-function {label  indent  infoP} {
    out "${indent}C-symbol: [::gi::g_function_info_get_symbol $infoP]"
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
    out "${indent}dir: $::gi::GIDirection::toName($dir)"

    set groupKey [dumpTypeInfoUnref  type  $indent  [::gi::g_arg_info_get_type $infoP]]
    $groupKey appearsOn $::lineNum
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

    # basic identification:  info struct's subtype, name, and namespace.
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $infoP]]
    set infoName [::gi::g_base_info_get_name $infoP]
    out "$indent${label}<${tn}> : ([::gi::g_base_info_get_namespace $infoP]) $infoName"

    # lineage of all containers.
    set lineage $infoName
    set walkP $infoP
    while {[set ctnrP [::gi::g_base_info_get_container $walkP]] > 0} {
        set lineage "[::gi::g_base_info_get_name $ctnrP] / $lineage"
        set walkP $ctnrP
    }
    if {$walkP != $infoP} {
        out "$indent    lineage: $lineage"
    }

    # arbitrary string attributes.  evidently uncommon.
    set name {}
    set value {}
    set header "$indent    attributes\n"
    set iterP [::dlr::lib::gi::struct::GIAttributeIter::packNew  iter]
    while {[::gi::g_base_info_iterate_attributes  $infoP  $iterP  name  value]} {
        out "$header$indent        $name : $value"
        set header {}
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
    set groupKey [dumpTypeInfo  $label  $indent  $typeInfoP]
    ::gi::g_base_info_unref $typeInfoP
    return $groupKey
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
    #out "$indent${label}typeInfo tag $tag : [::gi::g_info_type_to_string $tag]"
    #todo: g_info_type_to_string gives the wrong names.
    set dTyp  $( [dict exists $::gi::GITypeTag::toDlrType $tag]  ?  $::gi::GITypeTag::toDlrType($tag)  :  {} )
    out "$indent${label}typeInfo tag $tag : $::gi::GITypeTag::toName($tag) : $dTyp"

    #todo: param_type offers no upper limit to its index?  and, turns out, it's a bottomless recursion too.
    #loop i 0 1 {
        #dumpTypeInfoUnref  paramType  "$indent    "  \
            #[::gi::g_type_info_get_param_type $typeInfoP $i]
    #}

    set isP [::gi::g_type_info_is_pointer $typeInfoP]
    if {$isP} {
        out "$indent    is pointer."
    }

    # this is actually the length of each tuple within the array.
    set len [::gi::g_type_info_get_array_length $typeInfoP]
    if {$len >= 0} {
        out "$indent    tuple length $len"
    }

    set ifcType {}
    set ifcName {}
    if {$tag == $::gi::GITypeTag::toValue(INTERFACE)} {
        set ifcP  [::gi::g_type_info_get_interface $typeInfoP]
        set ifcType [::gi::g_info_type_to_string [::gi::g_base_info_get_type $ifcP]]
        set ifcName [::gi::g_base_info_get_name $ifcP]
        out "$indent    <${ifcType}> : ([::gi::g_base_info_get_namespace $ifcP]) $ifcName"
        ::gi::g_base_info_unref $ifcP
    }

    set gk [GroupKey fromType $tag $isP $ifcType $ifcName]
    return $gk
}

# command line.
lassign $::argv  ::metaAction  ::requireSpaces  ::inspectSpaces  ::namePattern
if {$::namePattern eq {}} {set ::namePattern * }

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
set ::lineNum 1
set ::tot [dict create]

# load the given prerequisite GI spaces.
foreach {giSpace  version  soPath} [string trim $::requireSpaces] {
    ::gi::loadSpace  $::metaAction  $giSpace  $version  $soPath
}

# load and dump all available infos in the given inspectSpaces.
foreach {giSpace  version  soPath} [string trim $::inspectSpaces] {
    loadSpace  $giSpace  $version  $soPath
    set roots [rootInfos]
    out "[llength $roots] total root infos"
    foreach infoP $roots {
        set name [::gi::g_base_info_get_name $infoP]
        if {[string match -nocase $::namePattern $name]} {
            dumpInfo  {}  {}  $infoP
        }
    }
}

reportGroups

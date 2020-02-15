# gizmo
# Copyright 2020 Mark Hubbard, a.k.a. "TheMarkitecht"
# http://www.TheMarkitecht.com
#
# Project home:  http://github.com/TheMarkitecht/gizmo
# gizmo is a GNOME / GTK+ 3 windowing shell for Jim Tcl (http://jim.tcl.tk/)
# gizmo helps you quickly develop modern cross-platform GUI apps in Tcl.
#
# This file is part of gizmo.
#
# gizmo is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# gizmo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with gizmo.  If not, see <https://www.gnu.org/licenses/>.


# this file contains all the dlr bindings for libgirepository functions.
# those can query GI metadata.  then gizmo scripts can call the functions that describes.

# script interpreter support.
alias  ::gi::get  set ;# allows "get" as an alternative to the one-argument "set", with much clearer intent.

# #################  compiler support  ############################
proc ::gi::pushCompiler {} {
    set ::gi::oldCompiler   $::dlr::compiler
    set ::dlr::compiler {
        set gtkFlags [exec pkg-config --cflags gtk+-3.0]
        set gtkLibs  [exec pkg-config --libs   gtk+-3.0]
        set giFlags  [list -I/usr/include/gobject-introspection-1.0 ]
        set giLibs   [list -lgirepository-1.0 ]
        #puts [list gcc  {*}$gtkFlags  --std=c11  -O0  -I.  -o $binFn  $cFn  {*}$gtkLibs]
        exec  gcc  {*}$giFlags  {*}$gtkFlags  --std=c11  -O0  -I.  \
            -o $binFn  $cFn  {*}$gtkLibs  {*}$giLibs
    }
}

proc ::gi::popCompiler {} {
    set ::dlr::compiler $::gi::oldCompiler
}

# #################  GNOME and GI simple types  ############################
# these are using ::dlr::typedef rather than ::gi::typedef because it's not initialized yet.
::dlr::typedef  int         gint
::dlr::typedef  u32         enum
::dlr::typedef  u32         GQuark
::dlr::typedef  gint        gboolean
::dlr::typedef  ptr         callback
::dlr::typedef  uLong       gsize

# based on GI_TYPE_TAG_*
::dlr::declareEnum  gi  gint  GITypeTag  {
    VOID       0
    BOOLEAN    1
    INT8       2
    UINT8      3
    INT16      4
    UINT16     5
    INT32      6
    UINT32     7
    INT64      8
    UINT64     9
    FLOAT     10
    DOUBLE    11
    GTYPE     12
    UTF8      13
    FILENAME  14
    ARRAY     15
    INTERFACE 16
    GLIST     17
    GSLIST    18
    GHASH     19
    ERROR     20
    UNICHAR   21
}
# also map many GITypeTag's to equivalent dlr::simple types.
#todo: the string types mapped to ascii here actually need e.g. ::dlr::simple::utf8
foreach {name typ} {
    VOID        ::dlr::simple::void
    BOOLEAN     ::dlr::simple::int
    INT8        ::dlr::simple::i8
    UINT8       ::dlr::simple::u8
    INT16       ::dlr::simple::i16
    UINT16      ::dlr::simple::u16
    INT32       ::dlr::simple::i32
    UINT32      ::dlr::simple::u32
    INT64       ::dlr::simple::i64
    UINT64      ::dlr::simple::u64
    FLOAT       ::dlr::simple::float
    DOUBLE      ::dlr::simple::double
    UTF8        ::dlr::simple::ascii
    FILENAME    ::dlr::simple::ascii
} {
    dict set  ::gi::GITypeTag::toDlrType  $::gi::GITypeTag::toValue($name)  $typ
}
#todo: delete
#set  ::gi::GITypeTag::memManagedNames  {INTERFACE ARRAY}

# don't use this.  it causes all subsequent find_by_name to fail.
#todo: change braces to quote marks?
::dlr::declareEnum  gi  gint  GIRepositoryLoadFlags  {
    LAZY    $(1 << 0)
}

::dlr::declareEnum  gi  gint  GIDirection  {
    IN       {}
    OUT      {}
    INOUT    {}
}
foreach {dir dlrDir} {
    IN       in
    OUT      out
    INOUT    inOut
} {
    dict set  ::gi::GIDirection::toDlrDirection  $::gi::GIDirection::toValue($dir)  $dlrDir
}

# #################  GNOME and GI structure types  ############################
# these are using ::dlr::declareStructType rather than ::gi::declareStructType because it's not initialized yet.

::gi::pushCompiler

::dlr::declareStructType  noScript  gi  GIAttributeIter  {
    {ptr        data      asInt}
    {ptr        data2     asInt}
    {ptr        data3     asInt}
    {ptr        data4     asInt}
}
proc ::dlr::lib::gi::struct::GIAttributeIter::packNew {packVarName} {
    upvar 1 $packVarName packed
    ::dlr::createBufferVar  packed  $::dlr::lib::gi::struct::GIAttributeIter::size
    ::dlr::simple::ptr::pack-byVal-asInt  packed  0  $::dlr::lib::gi::struct::GIAttributeIter::member::data::offset
    return [::dlr::addrOf  packed]
}

::dlr::declareEnum  gi  gint  GIInfoType  {
}

::gi::popCompiler

# #################  GI API function bindings  ############################
# these are using ::dlr::declareCallToNative rather than ::gi::declareCallToNative because it's not initialized yet.

# g_function_info_invoke is called in C instead of script, for speed.
alias  ::gi::callToNative  ::dlr::native::giCallToNative
# gi::free has to be declared here to be available for GI calls' memory management.
# binding it in C also makes it faster than binding in script.
alias  ::gi::free   dlr::native::giFreeHeap

# this does yield the same default repo pointer as the GI lib linked at compile time, in the same process, same attempt.
::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_irepository_get_default  {}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_irepository_require  {
    {in     byVal   ptr                     repository      asInt               }
    {in     byPtr   ascii                   giSpace         asString            }
    {in     byPtr   ascii                   version         asString            }
    {in     byVal   GIRepositoryLoadFlags   flags           asInt               }
    {out    byPtr   ptr                     error           asInt       ignore  }
}
#todo: error handling

# returns pointer (scriptPtr integer) to a GIFunctionInfo for the given function name.
# script is responsible for g_free'ing that pointer later.
#todo: script is responsible for g_free'ing that pointer later.  or is g_object_unref() better there?
::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_irepository_find_by_name  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
    {in     byPtr   ascii                   name            asString}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_irepository_get_c_prefix  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_irepository_get_shared_library  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
}

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_irepository_get_n_infos  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_irepository_get_info  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
    {in     byVal   gint                    index           asInt}
}

::dlr::declareCallToNative  cmd  gi  {byPtr ascii asString ignore}  g_base_info_get_namespace  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_base_info_get_container  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal GIInfoType asInt}  g_base_info_get_type  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byPtr ascii asString ignore}  g_info_type_to_string  {
    {in     byVal   GIInfoType              type      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byPtr ascii asString ignore}  g_base_info_get_name  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {void}  g_base_info_unref  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gboolean asInt}  g_base_info_iterate_attributes  {
    {in     byVal       ptr                   info      asInt}
    {in     byVal       ptr                   iterator  asInt}
    {out    byPtrPtr    ascii                 name      asString    ignore}
    {out    byPtrPtr    ascii                 value     asString    ignore}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_callable_info_get_return_type  {
    {in     byVal   ptr                     type      asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_callable_info_get_n_args  {
    {in     byVal   ptr                     callable      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_callable_info_get_arg  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_arg_info_get_type  {
    {in     byVal   ptr                     info      asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal GITypeTag asInt}  g_type_info_get_tag  {
    {in     byVal   ptr                     type      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_interface_info_get_n_signals  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_interface_info_get_signal  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_interface_info_get_n_methods  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_interface_info_get_method {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_object_info_get_n_signals  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_object_info_get_signal  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_object_info_get_n_methods  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_object_info_get_method {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_type_info_get_param_type  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gboolean asInt}  g_type_info_is_pointer  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_type_info_get_array_length  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_type_info_get_interface  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal GIDirection asInt}  g_arg_info_get_direction  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byPtr ascii asString ignore}  g_function_info_get_symbol  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gsize asInt}  g_struct_info_get_size  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_struct_info_get_n_fields  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_struct_info_get_field  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_field_info_get_offset  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_field_info_get_size  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_field_info_get_type  {
    {in     byVal   ptr                     info      asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gsize asInt}  g_union_info_get_size  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_union_info_get_n_fields  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_union_info_get_field  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal gboolean asInt}  g_union_info_is_discriminated  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_union_info_get_discriminator_offset  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_union_info_get_discriminator_type  {
    {in     byVal   ptr                     info      asInt}
}
# do unref

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_union_info_get_discriminator  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref



# #################  add-on dlr features supporting GI  ############################

# like ::dlr::loadLib, but for GNOME libraries.
#todo: more docs
proc ::gi::loadSpace {metaAction  giSpace  giSpaceVersion  fileNamePath} {
    set libAlias [giSpaceToLibAlias $giSpace]
    if {[exists ::gi::${libAlias}::version]} {
        # already loaded.
        return [get ::gi::${libAlias}::tlbHandle]
    }
    set errP 0
    set tlbP [::gi::g_irepository_require  $::gi::repoP  $giSpace  $giSpaceVersion  0  errP]
    # can't use ::g::checkGError here; it's not loaded yet.
    if {$errP != 0} {
        error "GI namespace not found: $giSpace $giSpaceVersion"
    }
    if {$tlbP == 0} {
        error "GI typelib not found: $giSpace $giSpaceVersion"
    }
    set ::gi::${libAlias}::tlbHandle $tlbP
    set ::gi::${libAlias}::version  $giSpaceVersion
    ::dlr::loadLib  $metaAction  $libAlias  $fileNamePath
    return $tlbP
}

proc ::gi::isSpaceLoaded {giSpace} {
    set libAlias [giSpaceToLibAlias $giSpace]
    return [exists ::gi::${libAlias}::tlbHandle]
}

proc ::gi::requireSpace {giSpace} {
    if { ! [::gi::isSpaceLoaded $giSpace]} {
        error "GI namespace '$giSpace' is required but is not already loaded."
    }
}

proc ::gi::giSpaceToLibAlias {giSpace} {
    set a [string tolower $giSpace]
    if {[string match *lib $a]} {
        return [string range $a 0 end-3]
    }
    return $a
}

# equivalent to ascii::unpack-scriptPtr-asString followed by ::gi::free.
#todo: eliminate this when we have extensible memActions.
proc ::gi::ascii::unpack-scriptPtr-asString-free {pointerIntValue} {
    set unpackedData [::dlr::simple::ascii::unpack-scriptPtr-asString $pointerIntValue]
    ::gi::free $pointerIntValue
    return $unpackedData
}

# can be used to declare new simple type based on an existing one.
proc ::gi::typedef {existingType  name} {
    ::dlr::typedef $existingType  $name
}

proc ::gi::declareEnum {giSpace  baseTypeSimpleBare  enumTypeBareName  valueMap} {
    set libAlias [giSpaceToLibAlias $giSpace]
    ::dlr::declareEnum $libAlias  $baseTypeSimpleBare  $enumTypeBareName  $valueMap
}

# this is the required first step before using a struct type.
#todo: documentation
proc ::gi::declareStructType {scriptAction  giSpace  structTypeName} {
    ::gi::requireSpace $giSpace
    set libAlias [giSpaceToLibAlias $giSpace]
    set sQal ::dlr::lib::${libAlias}::struct::${structTypeName}::
puts "declareStructType $sQal"
    set ${sQal}categories   $::dlr::struct::categories
    set ${sQal}scriptForms  $::dlr::struct::scriptForms

    # find structure info
    set sInfoP [::gi::g_irepository_find_by_name  $::gi::repoP  $giSpace  $structTypeName]
    if {$sInfoP == 0} {
        error "Type not found in '$giSpace': $structTypeName"
    }
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $sInfoP]]
    if {$tn != {struct}} {
        error "Expected struct type for '$structTypeName' but found '$tn' type instead."
    }
    set ${sQal}size  [::gi::g_struct_info_get_size $sInfoP]

    # iterate member info's
    set ${sQal}memberOrder [list]
    set typeMeta [list]
    set nMems [::gi::g_struct_info_get_n_fields $sInfoP]
    loop i 0 $nMems {
        set mInfoP [::gi::g_struct_info_get_field $sInfoP $i]
        set mName [::gi::g_base_info_get_name $mInfoP]
        set mTypeInfoP [::gi::g_field_info_get_type $mInfoP]
        lassign [::gi::typeToDescrip  $mTypeInfoP  struct  $mName]  \
            dir  passMethod  dlrType  parmName  scriptForm  memAction
if {$dlrType eq {}} {error "$dir  $passMethod  $dlrType  $parmName  $scriptForm  $memAction  $sQal"}
        set mQal ${sQal}member::${mName}::
        set ${mQal}type $dlrType
        set ${mQal}scriptForm $scriptForm
        set mPassType $( $passMethod eq {byVal}  ?  $dlrType  :  {::dlr::simple::ptr} )
        set ${mQal}offset [::gi::g_field_info_get_offset $mInfoP]
        if {{struct} in [get ${mPassType}::categories]} {
            # nested struct's members are stacked into sQal memberOrder as if they belong there.
            # for FFI and converter purposes, they do belong there.
            ::gi::includeStructMembers  $sQal  $mName  [get ${mQal}offset]  typeMeta  $mPassType
        } else {
            lappend ${sQal}memberOrder  $mName
            set ${mQal}typeMeta [::dlr::selectTypeMeta $mPassType]
            lappend typeMeta [get ${mQal}typeMeta]
        }
        ::gi::g_base_info_unref $mTypeInfoP
        ::gi::g_base_info_unref $mInfoP
    }
    ::gi::g_base_info_unref $sInfoP

    # prep FFI type record for this structure.
puts typeMeta=$typeMeta
    ::dlr::prepStructType  ${sQal}meta  $typeMeta

    # generate and apply converter scripts.
    if {[::dlr::refreshMeta] || ! [file readable [structConverterPath $libAlias $structTypeName]]} {
        ::dlr::generateStructConverters  $libAlias  $structTypeName
    }
    if {$scriptAction ni {noScript convert}} {
        error "Invalid script action: $scriptAction"
    }
    if {$scriptAction eq {convert}} {
        source [::dlr::structConverterPath  $libAlias  $structTypeName]
    }
}

# gather up the metadata of each member described by guestTypeName into hostSQal and &hostTypeMetaList.
# if any of guest's members are themselves structs by value, their members should have already been
# rolled into guest's memberOrder.
proc ::gi::includeStructMembers {hostSQal  hostMemberName  hostMOffset  &hostTypeMetaList  guestTypeName} {
    set gsQal ${guestTypeName}::
    if { ! [exists ${gsQal}memberOrder]} {
        error "'$guestTypeName' must be declared before '$hostSQal'.  Has its GI namespace already been loaded?"
    }
    foreach gmName [get ${gsQal}memberOrder] {
        set gmQal ${gsQal}member::${gmName}::
        set nestedMNameFull ${hostMemberName}::member::${gmName}
        set nmQal ${hostSQal}member::${nestedMNameFull}::

        set ${nmQal}offset  $( [get ${gmQal}offset] + $hostMOffset )
        set ${nmQal}type       [get ${gmQal}type]
        set ${nmQal}typeMeta   [get ${gmQal}typeMeta]
        set ${nmQal}scriptForm [get ${gmQal}scriptForm]

        lappend hostTypeMetaList [get ${gmQal}typeMeta]
        lappend ${hostSQal}memberOrder  $nestedMNameFull
    }
}

# this is the required first step before using a union type.
# unions are treated essentially as structs which can't be automatically converted,
# because applying the wrong conversion might throw an error, or produce
# credible but erroneous data.  instead the app must decide which converter
# to use in each situation, based on the union's discriminator value, if
# there is one, or on some broader context of the app.
# so, unions offer only one scriptForm, asNative.
proc ::gi::declareUnionType {scriptAction  giSpace  unionTypeName} {
    ::gi::requireSpace $giSpace
    set libAlias [giSpaceToLibAlias $giSpace]
    set sQal ::dlr::lib::${libAlias}::union::${unionTypeName}::
puts "declareUnionType $sQal"
    set ${sQal}categories   $::dlr::union::categories
    set ${sQal}scriptForms  $::dlr::union::scriptForms

    # find union info
    set sInfoP [::gi::g_irepository_find_by_name  $::gi::repoP  $giSpace  $unionTypeName]
    if {$sInfoP == 0} {
        error "Type not found in '$giSpace': $unionTypeName"
    }
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $sInfoP]]
    if {$tn != {union}} {
        error "Expected union type for '$unionTypeName' but found '$tn' type instead."
    }
    set ${sQal}size  [::gi::g_union_info_get_size $sInfoP]

    # prep FFI type record for this union.
#todo: select largest union field and largest alignment.  or skip that since unions by value aren't allowed.
puts typeMeta=$typeMeta
#    ::dlr::prepunionType  ${sQal}meta  $typeMeta

    # generate and apply converter scripts.
    if {[::dlr::refreshMeta] || ! [file readable [unionConverterPath $libAlias $unionTypeName]]} {
        ::dlr::generateUnionConverters  $libAlias  $unionTypeName
    }
    if {$scriptAction ni {noScript convert}} {
        error "Invalid script action: $scriptAction"
    }
    if {$scriptAction eq {convert}} {
        source [::dlr::structConverterPath  $libAlias  $unionTypeName]
    }
}

proc ::gi::getConstantValue {constInfoP} {
    # determine data type, and map it to a dlr type.
    set typeInfoP [::gi::g_constant_info_get_type $constInfoP]
    lassign [::gi::typeToDescrip  $typeInfoP  const  _#_const_#_ ]  \
        dlrDir  passMethod  dlrType  dlrName  scriptForm  memAction
    ::gi::g_base_info_unref  $typeInfoP
    if {{integral} ni [get ${dlrType}::categories]} {
        error "Constant is not of an integral type: [::gi::g_base_info_get_name $constInfoP]"
    }

    # fetch value.
    ::dlr::createBufferVar  value  $::dlr::simple::GIArgument::size]
    set sz [::gi::g_constant_info_get_value  $constInfoP  [::dlr::addrOf  value]]
    set unpacker  [::dlr::converterName  unpack  $dlrType  byVal  $scriptForm  ignore]
    return [$unpacker $value]
}

# base class for all script classes representing GNOME calls and data.
# in other words, this is the script class representing GObject.
#todo: is that accurate?  if so, can this be renamed to gi.GObject ?
# because :: doesn't work; Jim causes "invalid command name".  i don't feel like fixing Jim there.
# dots work because class names are represented by commands, not variables.
# scripts can use global commands without giving qualifiers.
# as an added bonus, braces around embedded var names aren't needed because dots aren't var name chars.
# devs from other languages can see the convention as similar to Java or C#.
# Tk devs will have to adjust.
#todo: eliminate the leading dot.
#todo: submit a docs patch for namespaced classes, unsupported.
class gi.BaseClass {
    giSelf  0
}
#todo: automatic cleanup.  in destructor?

# declares the name of a new script class.
proc ::gi::declareClass {giSpace  scriptClassNameBare  baseClassList  instanceVarsDict} {
    ::gi::requireSpace $giSpace
    set libAlias [giSpaceToLibAlias $giSpace]
    set fullCls $libAlias.$scriptClassNameBare
    class  $fullCls  [list gi.BaseClass {*}$baseClassList]  $instanceVarsDict
    ::gi::declareMethods  $giSpace  $scriptClassNameBare
}

#todo: refactor this family of procs.  must be able to defer declaration of any info until later,
# because there's widespread interdependence across info types, and mutual dependence.  e.g. some
# structs contain unions, and many unions are made of structs.  or, a constant could be a pointer
# to a function, whose parm is a struct containing an array, whose length is a constant.
proc ::gi::declareAllInfos {giSpace} {
    ::gi::declareAllStructTypes     $giSpace
    ::gi::declareAllClasses         $giSpace
}

proc ::gi::declareAllClasses {giSpace} {
    ::gi::forRootInfos  $giSpace  object  {
        ::gi::declareClass  $giSpace  $name  {}  {}
    }
}

proc ::gi::declareAllStructTypes {giSpace} {
    ::gi::forRootInfos  $giSpace  struct  {
        ::gi::declareStructType  convert  $giSpace  $name
    }
}

proc ::gi::forRootInfos {giSpace  infoTypeName  script} {
    set nInfos [::gi::g_irepository_get_n_infos  $::gi::repoP  $giSpace]
    loop i 0 $nInfos {
        set infoP  [::gi::g_irepository_get_info  $::gi::repoP  $giSpace  $i]
        set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $infoP]]
        set name [::gi::g_base_info_get_name $infoP]
        if {$tn eq $infoTypeName} $script
    }
}

# detects and declares all methods of a class, in bulk.
# leading double-colons are used ahead of the dotted class name in this routine.
# however they aren't needed in app script, nor in other ::gi procs.
proc ::gi::declareMethods {giSpace  scriptClassNameBare} {
    set libAlias [giSpaceToLibAlias $giSpace]
    set fullCls ::$libAlias.$scriptClassNameBare
    if { ! [exists -command $fullCls]} {
        error "Class $fullCls does not exist."
    }
puts class=$fullCls

    # find all methods from GI info.
#todo: support GInterface the same as GObject.
    set oInfoP [::gi::g_irepository_find_by_name  $::gi::repoP  $giSpace  $scriptClassNameBare]
    if {$oInfoP == 0} {
        error "Type not found in '$giSpace': $scriptClassNameBare"
    }
    set tn [::gi::g_info_type_to_string [::gi::g_base_info_get_type $oInfoP]]
    if {$tn != {object}} {
        error "Expected object type for '$scriptClassNameBare' but found '$tn' type instead."
    }
    set nMeth [::gi::g_object_info_get_n_methods $oInfoP]
    loop i 0 $nMeth {
        set mInfoP [::gi::g_object_info_get_method $oInfoP $i]
        set mName  [::gi::g_base_info_get_name $mInfoP]
        set fnName [::gi::g_function_info_get_symbol $mInfoP]
puts method=$mName

        # declare a native call.
        set parmsDescrip [list]
        set supportedCall 1
        set nArgs [::gi::g_callable_info_get_n_args $mInfoP]
        loop i 0 $nArgs {
puts arg=$i
            set descrip [::gi::argToDescrip [::gi::g_callable_info_get_arg $mInfoP $i] $scriptClassNameBare]
            lappend parmsDescrip $descrip
            lassign $descrip  dir  passMethod  type  name  scriptForm  memAction
            if {$type eq {}} {set unsupportedCall 0}
        }
        set descrip [::gi::returnToDescrip $mInfoP]
        lassign $descrip  dir  passMethod  type  name  scriptForm  memAction
        if {$type eq {}} {set unsupportedCall 0}
        ::dlr::declareCallToNative  wrap  $libAlias  $descrip  $fnName  $parmsDescrip

        if {$supportedCall} {
#todo: factor out to a distinct generator routine.  tie into refreshMeta.
            # wrap that native call in a script class method.
            # each parameter will be thunked verbatim, except 'self'.
            set mFormalParms [list]
            set dlrCallParms [list]
            foreach pDesc $parmsDescrip {
                lassign $pDesc  dir  passMethod  type  name  scriptForm  memAction
                if {$name eq {self}} {
                    lappend dlrCallParms \$giSelf
                } else {
                    if {$passMethod eq {byVal}} {
                        lappend mFormalParms $name
                        lappend dlrCallParms \$$name
                    } else {
                        lappend mFormalParms &$name
                        lappend dlrCallParms $name
                    }
                }
            }
            if {$mName eq {new}} {
                # special case wraps a constructor.  many of these constructors accept parameters.
                # in Jim it must be implemented as a factory in a class method.
                # it's called 'new', to match GNOME's convention.
                # first, Jim's own 'new' command is renamed out of the way.
                rename "$fullCls new" "$fullCls _new"
                set body "\n    set  objP  \[ ::dlr::lib::${libAlias}::${fnName}::call  $dlrCallParms \] \n"
                append body "\n    if { \$objP == 0 } { error \"Object constructor failed: $fnName\" } \n"
                append body "\n    return \[ $fullCls _new \[ list giSelf \$objP giSpace $giSpace \] \] \n"
                proc  "$fullCls new"  $mFormalParms  $body
            } else {
                set body "\n    ::dlr::lib::${libAlias}::${fnName}::call  $dlrCallParms \n"
                $fullCls  method  $mName  $mFormalParms  $body
            }
        }
    }
}

proc ::gi::returnToDescrip {callableInfoP} {
    set typeInfoP  [::gi::g_callable_info_get_return_type $callableInfoP]
    lassign [::gi::typeToDescrip $typeInfoP return noName]  \
        dlrDir  passMethod  dlrType  dlrName  scriptForm  memAction
    ::gi::g_base_info_unref  $typeInfoP
    return  [list  $passMethod  $dlrType  $scriptForm  $memAction]
}

proc ::gi::argToDescrip {argInfoP  scriptClassNameBare} {
    set dir [::gi::g_arg_info_get_direction $argInfoP]
    set dlrDir $::gi::GIDirection::toDlrDirection($dir)
    set dlrName  [::gi::g_base_info_get_name $argInfoP]

    set typeInfoP  [::gi::g_arg_info_get_type $argInfoP]
    lassign [::gi::typeToDescrip $typeInfoP $dlrDir $dlrName]  \
        dlrDir  passMethod  dlrType  dlrName  scriptForm  memAction
    ::gi::g_base_info_unref  $typeInfoP

    if {$passMethod eq {byPtr} && $dlrType eq $scriptClassNameBare} {
        # assume this is the "self" parm, to pass the object instance pointer to the function.
        set dlrName self
    }

    return  [list  $dlrDir  $passMethod  $dlrType  $dlrName  $scriptForm  $memAction]
}

proc ::gi::descripCase-dlrByVal {} { uplevel 1 {
    set dlrType $::gi::GITypeTag::toDlrType($tag)
    set passMethod byVal
}}

proc ::gi::descripCase-dlrByPtr {} { uplevel 1 {
    #set ifcP  [::gi::g_type_info_get_interface $typeInfoP]
    #set dlrType [::gi::g_base_info_get_name $ifcP]
    #::gi::g_base_info_unref $ifcP
    set dlrType $::gi::GITypeTag::toDlrType($tag)
    set passMethod byPtr
}}

proc ::gi::descripCase-forcePtr {} { uplevel 1 {
    set dlrType ::dlr::simple::ptr
    set passMethod byVal
}}

proc ::gi::descripCase-enum {} { uplevel 1 {
    set dlrType ::dlr::simple::enum ;# defined by gi.tcl.
}}

proc ::gi::descripCase-callback {} { uplevel 1 {
    set dlrType ::dlr::simple::callback ;# defined by gi.tcl.
}}

proc ::gi::descripCase-arrayByVal {} { uplevel 1 {
    set dlrType ::dlr::lib::g::struct::Array ;# defined by g.tcl which must be loadSpace'd first.
}}

proc ::gi::descripCase-structByVal {} { uplevel 1 {
    set libAlias [giSpaceToLibAlias [::gi::g_base_info_get_namespace $ifcP]]
    set dlrType ::dlr::lib::${libAlias}::struct::$ifcName
}}

proc ::gi::descripCase-unionByVal {} { uplevel 1 {
    # prevent passing unions by value.
    # GNOME does that in at least 6 places, some are in Widget class!
    # libffi has serious trouble with that:
    # https://github.com/libffi/libffi/issues/33
    # https://stackoverflow.com/questions/40354500/how-do-i-create-an-ffi-type-that-represents-a-union
    # issue is tagged to fix in libffi 4.0 but that's years away from 2020.

    # return empty string to indicate unsupported.
    set dlrType {}
}}

proc ::gi::descripCase-unionNested {} { uplevel 1 {
puts @@ifcP=[format $::dlr::ptrFmt $ifcP]
puts ifcType=$ifcType
puts ifcName=$ifcName
flush stdout
puts structbyval=[::gi::g_base_info_get_namespace $ifcP]=[::gi::g_base_info_get_name $ifcP]

    set libAlias [giSpaceToLibAlias [::gi::g_base_info_get_namespace $ifcP]]
    set dlrType ::dlr::lib::${libAlias}::union::$ifcName
}}

proc ::gi::typeToDescrip {typeInfoP dir parmName} {
    if { ! [exists ::gi::descripCases]} {
        # match actual situation to one row of this dispatch table of different cases.
        # the matching row indicates the usable handler.
        # that is the topmost row where every cell in the row matches the actual situation.
        # each table cell can contain a pattern for [string match], or a list of those.
        # if any pattern in the list matches, the cell is a match.
        # a handler name may appear on more than one row; that's fine.
        # pattern columns:
        #     dir           tagName         passMethod  ifcType         haveDlrType handler
        set ::gi::descripCases {
            { *             INTERFACE       *           {enum flags}    *           enum               }
            { *             INTERFACE       byVal       callback        *           callback           }
            { *             INTERFACE       byVal       struct          *           structByVal        }
            {{in out inOut} INTERFACE       byVal       union           *           unionByVal         }
            {{struct const} INTERFACE       byVal       union           *           unionNested        }
            { *             ARRAY           byVal       *               *           arrayByVal         }
            { *             *               byVal       *               yes         dlrByVal           }
            { *             *               byPtr       *               yes         dlrByPtr           }
            { *             *               byPtr       *               *           forcePtr           }
        }

        # verify table integrity.
        set allHandlers [lmap row $::gi::descripCases {lindex $row end}]
        # verify each row.
        foreach handler $allHandlers {
            if { ! [exists -command ::gi::descripCase-$handler]} {
                error "Handler '$handler' is mentioned in dispatch table, but is not implemented."
            }
        }
        # verify each proc.
        foreach cmd [info commands ::gi::descripCase-*] {
            set handler [string range $cmd 18 end]
            if {$handler ni $allHandlers} {
                error "Handler '$handler' is implemented, but not mentioned in dispatch table."
            }
        }
    }

    # ### select handler.
    # detect or derive certain conditions which can be used during handler selection.
    set passMethod $( [::gi::g_type_info_is_pointer $typeInfoP]  ?  {byPtr}  :  {byVal} )
    set tag [::gi::g_type_info_get_tag $typeInfoP]
    set tagName $::gi::GITypeTag::toName($tag)
    set haveDlrType $( [exists ::gi::GITypeTag::toDlrType($tag)]  ?  {yes}  :  {no} )
    set ifcType {}
    set ifcName {}
    if {$tag == $::gi::GITypeTag::toValue(INTERFACE)} {
        set ifcP  [::gi::g_type_info_get_interface $typeInfoP]
        set ifcType [::gi::g_info_type_to_string [::gi::g_base_info_get_type $ifcP]]
        set ifcName [::gi::g_base_info_get_name $ifcP]
puts "interface: <$ifcType> $ifcName"
    }

    # search the rows for a match.
    set foundHandler {}
    foreach row $::gi::descripCases {
        set rowOK 1
        foreach col {0 1 2 3 4} var {dir  tagName  passMethod  ifcType  haveDlrType} {
            set colOK 0
            foreach pat [lindex $row $col] {
                set colOK $( $colOK || [string match $pat [get $var]] )
            }
            set rowOK $( $rowOK && $colOK )
        }
        if {$rowOK} {
            set foundHandler [lindex $row end]
            break
        }
    }
    # error if no handler was found.
    if {$foundHandler eq {}} {
        error "Unsupported configuration for data type:  $dir  $tagName  $passMethod  $ifcType"
    }

    # ### compose description per the chosen handler.
    set memAction  ignore
    #todo: set memAction per the ownership transfer type.
    ::gi::descripCase-$foundHandler
    if {$dlrType eq {}} {
        set scriptForm {}
    } else {
        set scriptForm  [lindex [::dlr::validScriptForms $dlrType] 0]
    }
    #todo: unref's and cleanup.
    return  [list  $dir  $passMethod  $dlrType  $parmName  $scriptForm  $memAction]
}

# like ::dlr::declareCallToNative, but for GNOME calls instead (those described by GI).
# parameters and most other metadata are obtained directly from GI and don't
# have to be declared by script.
# giSpace shall always be passed to ::gi::declareCallToNative in proper case, such as Gtk.
# the equivalent libAlias shall always be derived as [string tolower $giSpace], with
# any "lib" suffix removed from the end.  use giSpaceToLibAlias for that.
# that's the version that shall always be passed to ::dlr::declareCallToNative.
# simple types and all metadata reside as usual under ::dlr and ::dlr::lib::.
# libgirepository functions are aliased into ::gi::$fnName
# features of the target native library are aliased into ::$libAlias, usually as Jim OO classes.
#todo: obsolete??
proc ::gi::declareCallToNative {scriptAction  giSpace  returnTypeDescrip  fnName  parmsDescrip} {
    ::gi::requireSpace $giSpace
    set libAlias [giSpaceToLibAlias $giSpace]
    set fQal ::dlr::lib::${libAlias}::${fnName}::

    # get GI callable info.
    set fnInfoP [::gi::g_irepository_find_by_name  $::gi::repoP  GLib  assertion_message]
#todo: error check

    # query all metadata from GI callable.
#todo: implement declareCallToNative

    # pass callable info to prepMetaBlob

}

proc ::gi::declareSignalHandler {scriptAction  giSpace  returnTypeDescrip  fnName  parmsDescrip} {
    ::gi::requireSpace $giSpace
    set libAlias [giSpaceToLibAlias $giSpace]
    set fQal ::dlr::lib::${libAlias}::${fnName}::

    # get GI callable info.
    set fnInfoP [::gi::g_irepository_find_by_name  $::gi::repoP  GLib  assertion_message]

    # query all metadata from GI callable.
#todo: implement declareSignalHandler

    # pass callable info to prepMetaBlob
}


#todo: when declaring gtk classes, automatically fit them into Jim OO paradigm, all under ::Gtk

# #################  finish initializing gi package  ############################

set ::gi::repoP  [::gi::g_irepository_get_default]

#todo: use typed pointers throughout: a Jim class that holds a GObject pointer and its type info, and automatically verify that before passing pointer to another gnome func.
# and maybe holds lifetime info also, to help with automatic memory management.

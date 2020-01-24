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

# #################  GNOME and GI simple types  ############################
::dlr::typedef  int  gint
::dlr::typedef  u32  enum

::dlr::typedef  enum  GIRepositoryLoadFlags

# #################  GI API function bindings  ############################

# g_function_info_invoke is called in C instead of script, for speed.
alias  ::gi::callToNative  ::dlr::native::giCallToNative

# this does yield the same default repo pointer as the GI lib linked at compile time, in the same process, same attempt.
::dlr::declareCallToNative  applyScript  gi  {ptr asInt}  g_irepository_get_default  {}
alias  ::gi::repository::get_default   ::dlr::lib::gi::g_irepository_get_default::call

::dlr::declareCallToNative  applyScript  gi  {ptr asInt}  g_irepository_require  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   namespace       asString}
    {in     byPtr   ascii                   version         asString}
    {in     byVal   GIRepositoryLoadFlags   flags           asInt}
    {out    byPtr   ptr                     error           asInt}
}
#todo: error handling
alias  ::gi::repository::require   ::dlr::lib::gi::g_irepository_require::call

#todo: rename giFindFunction in dlrNative, to conform to GI API names.  but not giCallToNative; its parms and behavior differ.

# g_irepository_find_by_name is called in C instead of script because it inexplicably fails with
# "assert typelib != null" when called by script.  but all parameters looked good in gdb then.
alias  ::gi::repository::find_by_name  ::dlr::native::giFindFunction
#::dlr::declareCallToNative  applyScript  gi  {ptr asInt}  g_irepository_find_by_name  {
    #{in     byVal   ptr                     repository      asInt}
    #{in     byPtr   ascii                   namespace       asString}
    #{in     byPtr   ascii                   name            asString}
#}
#alias  ::gi::repository::find_by_name   ::dlr::lib::gi::g_irepository_find_by_name::call

::dlr::declareCallToNative  applyScript  gi  {ptr asInt}  g_irepository_get_c_prefix  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   namespace       asString}
}
alias  ::gi::repository::get_c_prefix   ::dlr::lib::gi::g_irepository_get_c_prefix::call

::dlr::declareCallToNative  applyScript  gi  {ptr asInt}  g_irepository_get_shared_library  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   namespace       asString}
}
alias  ::gi::repository::get_shared_library   ::dlr::lib::gi::g_irepository_get_shared_library::call

::dlr::declareCallToNative  applyScript  gi  {gint asInt}  g_callable_info_get_n_args  {
    {in     byVal   ptr                     callable      asInt}
}
alias  ::gi::callable_info::get_n_args   ::dlr::lib::gi::g_callable_info_get_n_args::call

# #################  add-on dlr features supporting GI  ############################

# like ::dlr::declareCallToNative, but for GNOME calls instead (those described by GI).
# parameters and most other metdata are obtained directly from GI and don't
# have to be declared by script.
proc ::gi::declareCallToNative {scriptAction  libAlias  returnTypeDescrip  fnName  parmsDescrip} {
    set fQal ::dlr::lib::${libAlias}::${fnName}::

    # get GI callable info.

    # query all metadata from GI callable.

    # pass callable info to prepMetaBlob

    # memorize metadata for parms.
    set order [list]
    set orderNative [list]
    set typesMeta [list]
    set parmFlagsList [list]
    foreach parmDesc $parmsDescrip {
        lassign $parmDesc  dir  passMethod  type  name  scriptForm
        set pQal ${fQal}parm::${name}::

        lappend order $name
        lappend orderNative ${pQal}native

        if {$dir ni $::dlr::directions} {
            error "Invalid direction of flow was given."
        }
        set ${pQal}dir  $dir
        lappend parmFlagsList $::dlr::directionFlags($dir)

        if {$passMethod ni $::dlr::passMethods} {
            error "Invalid passMethod was given."
        }
        set ${pQal}passMethod  $passMethod

        set fullType [qualifyTypeName $type $libAlias]
        set ${pQal}type  $fullType
        set ${pQal}passType $( $passMethod eq {byPtr} ? {::dlr::simple::ptr} : $fullType )
        lappend typesMeta [selectTypeMeta [get ${pQal}passType]]

        validateScriptForm $fullType $scriptForm
        set ${pQal}scriptForm  $scriptForm

        # this version uses only byVal converters, and wraps them in script for byPtr.
        # in future, the converters might be allowed to implement byPtr also, for more speed etc.
        set ${pQal}packer   [converterName   pack $fullType byVal $scriptForm]
        set ${pQal}unpacker [converterName unpack $fullType byVal $scriptForm]

        if {$passMethod eq {byPtr}} {
            set ${pQal}targetNativeName  ${pQal}targetNative
        }
    }
    set ${fQal}parmOrder        $order
    set ${fQal}parmOrderNative  $orderNative
    # parmOrderNative is also derived and memorized here, along with the rest,
    # in case the app needs to change it before using generateCallProc.

    # memorize metadata for return value.
    # it does not support other variable names for the native value, since that's generally hidden from scripts anyway.
    # it's always "out byVal" but does support different types and scriptForms.
    # it's not practical to support "out byPtr" here because there are many variations of
    # how the pointer's target was allocated, who is responsible for freeing that ram, etc.
    # instead that must be left to the script app to deal with.
    set rQal ${fQal}return::
    lassign $returnTypeDescrip  type scriptForm
    set fullType [qualifyTypeName $type $libAlias]
    set ${rQal}type  $fullType
    validateScriptForm $fullType $scriptForm
    set ${rQal}scriptForm  $scriptForm
    set ${rQal}unpacker  [converterName unpack $fullType byVal $scriptForm]
    # FFI requires padding the return buffer up to sizeof(ffi_arg).
    # on a big endian machine, that means unpacking from a higher address.
    set ${rQal}padding 0
    if {[get ${fullType}::size] < $::dlr::simple::ffiArg::size && $::dlr::endian eq {be}} {
        set ${rQal}padding  $($::dlr::simple::ffiArg::size - [get ${fullType}::size])
    }
    set rMeta [selectTypeMeta $fullType]

    if {[refreshMeta] || ! [file readable [callWrapperPath $libAlias $fnName]]} {
        generateCallProc  $libAlias  $fnName  ::giCallToNative
    }

    if {$scriptAction ni {applyScript noScript}} {
        error "Invalid script action: $scriptAction"
    }
    if {$scriptAction eq {applyScript}} {
        source [callWrapperPath  $libAlias  $fnName]
    }

    # prepare a metaBlob to hold dlrNative and FFI data structures.
    # do this last, to prevent an ill-advised callToNative using half-baked metadata
    # after an error preparing the metadata.  callToNative can't happen without this metaBlob.
    prepMetaBlob  ${fQal}meta  [::dlr::fnAddr  $fnName  $libAlias]  \
        ${rQal}native  $rMeta  $orderNative  $typesMeta  $parmFlagsList
}


#todo: when declaring gtk classes, fit them into Jim OO paradigm, all under ::gtk

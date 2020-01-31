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

# compiler support.
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

# #################  GNOME and GI simple types  ############################
::dlr::typedef  int  gint
::dlr::typedef  u32  enum
::dlr::typedef  u32  GQuark
::dlr::typedef  gint gboolean

::dlr::typedef  enum  GIRepositoryLoadFlags
# don't use this.  it causes all subsequent find_by_name to fail.
set ::gi::REPOSITORY_LOAD_FLAG_LAZY $(1 << 0)

# #################  GNOME and GI structure types  ############################
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
}

# #################  GI API function bindings  ############################

# g_function_info_invoke is called in C instead of script, for speed.
alias  ::gi::callToNative  ::dlr::native::giCallToNative
# gi::free has to be declared here to be available for GI calls' memory management.
# binding it in C also makes it faster than binding in script.
alias  ::gi::free   dlr::native::giFreeHeap

# this does yield the same default repo pointer as the GI lib linked at compile time, in the same process, same attempt.
::dlr::declareCallToNative  applyScript  gi  {byVal ptr asInt}  g_irepository_get_default  {}
alias  ::gi::repository::get_default   ::dlr::lib::gi::g_irepository_get_default::call

::dlr::declareCallToNative  applyScript  gi  {byVal ptr asInt}  g_irepository_require  {
    {in     byVal   ptr                     repository      asInt               }
    {in     byPtr   ascii                   giSpace         asString            }
    {in     byPtr   ascii                   version         asString            }
    {in     byVal   GIRepositoryLoadFlags   flags           asInt               }
    {out    byPtr   ptr                     error           asInt       ignore  }
}
#todo: error handling
alias  ::gi::repository::require   ::dlr::lib::gi::g_irepository_require::call

# returns pointer (scriptPtr integer) to a GIFunctionInfo for the given function name.
# script is responsible for g_free'ing that pointer later.
#todo: script is responsible for g_free'ing that pointer later.  or is g_object_unref() better there?
::dlr::declareCallToNative  applyScript  gi  {byVal ptr asInt}  g_irepository_find_by_name  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
    {in     byPtr   ascii                   name            asString}
}
alias  ::gi::repository::find_by_name   ::dlr::lib::gi::g_irepository_find_by_name::call

::dlr::declareCallToNative  applyScript  gi  {byVal ptr asInt}  g_irepository_get_c_prefix  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
}
alias  ::gi::repository::get_c_prefix   ::dlr::lib::gi::g_irepository_get_c_prefix::call

::dlr::declareCallToNative  applyScript  gi  {byVal ptr asInt}  g_irepository_get_shared_library  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
}
alias  ::gi::repository::get_shared_library   ::dlr::lib::gi::g_irepository_get_shared_library::call

::dlr::declareCallToNative  applyScript  gi  {byVal gint asInt}  g_callable_info_get_n_args  {
    {in     byVal   ptr                     callable      asInt}
}
alias  ::gi::callable_info::get_n_args   ::dlr::lib::gi::g_callable_info_get_n_args::call

::dlr::declareCallToNative  applyScript  gi  {byVal gint asInt}  g_irepository_get_n_infos  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
}
alias  ::gi::repository::get_n_infos   ::dlr::lib::gi::g_irepository_get_n_infos::call

::dlr::declareCallToNative  applyScript  gi  {byVal ptr asInt}  g_irepository_get_info  {
    {in     byVal   ptr                     repository      asInt}
    {in     byPtr   ascii                   giSpace         asString}
    {in     byVal   gint                    index           asInt}
}
alias  ::gi::repository::get_info   ::dlr::lib::gi::g_irepository_get_info::call

::dlr::declareCallToNative  applyScript  gi  {byVal enum asInt}  g_base_info_get_type  {
    {in     byVal   ptr                     info      asInt}
}
alias  ::gi::base_info::get_type   ::dlr::lib::gi::g_base_info_get_type::call

::dlr::declareCallToNative  applyScript  gi  {byPtr ascii asString ignore}  g_info_type_to_string  {
    {in     byVal   enum                    type      asInt}
}
alias  ::gi::info_type_to_string   ::dlr::lib::gi::g_info_type_to_string::call

::dlr::declareCallToNative  applyScript  gi  {byPtr ascii asString ignore}  g_base_info_get_name  {
    {in     byVal   ptr                     info      asInt}
}
alias  ::gi::base_info::get_name   ::dlr::lib::gi::g_base_info_get_name::call

::dlr::declareCallToNative  applyScript  gi  {byVal gboolean asInt}  g_base_info_iterate_attributes  {
    {in     byVal       ptr                   info      asInt}
    {in     byVal       ptr                   iterator  asInt}
    {out    byPtrPtr    ascii                 name      asString    ignore}
    {out    byPtrPtr    ascii                 value      asString    ignore}
}
alias  ::gi::base_info::iterate_attributes   ::dlr::lib::gi::g_base_info_iterate_attributes::call

# #################  add-on dlr features supporting GI  ############################

proc ::gi::giSpaceToLibAlias {giSpace} {
    set a [string tolower $giSpace]
    if {[string match *lib $a]} {
        return [string range $a 0 end-3]
    }
    return $a
}

# equivalent to ascii::unpack-scriptPtr-asString followed by ::gi::free.
proc ::gi::ascii::unpack-scriptPtr-asString-free {pointerIntValue} {
    set unpackedData [::dlr::simple::ascii::unpack-scriptPtr-asString $pointerIntValue]
    ::gi::free $pointerIntValue
    return $unpackedData
}

proc ::gi::declareStructType {scriptAction  giSpace  structTypeName  membersDescrip} {
    set libAlias [giSpaceToLibAlias $giSpace]
    ::dlr::declareStructType $scriptAction  $libAlias  $structTypeName  $membersDescrip
    #todo: fetch struct members from GI so they don't have to be declared.
}

# like ::dlr::declareCallToNative, but for GNOME calls instead (those described by GI).
# parameters and most other metadata are obtained directly from GI and don't
# have to be declared by script.
# giSpace shall always be passed to ::gi::declareCallToNative in proper case, such as Gtk.
# the equivalent libAlias shall always be derived as [string tolower $giSpace], with
# any "lib" suffix removed from the end.  use giSpaceToLibAlias for that.
# that's the version that shall always be passed to ::dlr::declareCallToNative.
# simple types and all metadata reside as usual under ::dlr and ::dlr::lib::.
# libgirepository functions are aliased into ::gi::$class::$fnNameBare
# features of the target native library are aliased into ::$libAlias, usually as Jim OO classes.
proc ::gi::declareCallToNative {scriptAction  giSpace  version  returnTypeDescrip  fnName  parmsDescrip} {
    set libAlias [giSpaceToLibAlias $giSpace]
    set fQal ::dlr::lib::${libAlias}::${fnName}::

    set err 0
    set tlbP [::dlr::lib::gi::g_irepository_require::call  $::gi::repoP  $giSpace  $version  0  err]
    if {$err != 0} {
        error "GI namespace '$giSpace' not found."
    }
    if {$tlbP == 0} {
        error "GI typelib '$giSpace' not found."
    }

    # get GI callable info.
    set fnInfoP [::gi::repository::find_by_name  $::gi::repoP  GLib  assertion_message]

    # query all metadata from GI callable.
#todo: implement declareCallToNative

    # pass callable info to prepMetaBlob

}

proc ::gi::declareSignalHandler {scriptAction  giSpace  version  returnTypeDescrip  fnName  parmsDescrip} {
    set libAlias [giSpaceToLibAlias $giSpace]
    set fQal ::dlr::lib::${libAlias}::${fnName}::

    set err 0
    set tlbP [::dlr::lib::gi::g_irepository_require::call  $::gi::repoP  $giSpace  $version  0  err]
    if {$err != 0} {
        error "GI namespace '$giSpace' not found."
    }
    if {$tlbP == 0} {
        error "GI typelib '$giSpace' not found."
    }

    # get GI callable info.
    set fnInfoP [::gi::repository::find_by_name  $::gi::repoP  GLib  assertion_message]

    # query all metadata from GI callable.
#todo: implement declareSignalHandler

    # pass callable info to prepMetaBlob
}


#todo: when declaring gtk classes, automatically fit them into Jim OO paradigm, all under ::Gtk

# #################  finish initializing gi package  ############################

set ::gi::repoP  [::gi::repository::get_default]

#todo: move this feature into a new variant ::gi::loadLib
#todo: make ::gi::loadLib take the giSpace version number so it's not repeated in each declaration.
#todo: reinstate.
#source  [file join [file dirname [info script]]  glib.tcl]
#source  [file join [file dirname [info script]]  gtk.tcl]

set ::dlr::compiler  $::gi::oldCompiler

#todo: create a Jim class that holds a GObject pointer and its type info, and automatically verify that before passing pointer to another gnome func.
# and maybe holds lifetime info also, to help with automatic memory management.

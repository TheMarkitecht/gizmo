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

::dlr::typedef  enum  GITypeTag

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
    return [::dlr::addrOf  packed]
}

# #################  GI API function bindings  ############################

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

::dlr::declareCallToNative  cmd  gi  {byVal enum asInt}  g_base_info_get_type  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byPtr ascii asString ignore}  g_info_type_to_string  {
    {in     byVal   enum                    type      asInt}
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

::dlr::declareCallToNative  cmd  gi  {byVal gint asInt}  g_object_info_get_n_signals  {
    {in     byVal   ptr                     info      asInt}
}

::dlr::declareCallToNative  cmd  gi  {byVal ptr asInt}  g_object_info_get_signal  {
    {in     byVal   ptr                     info      asInt}
    {in     byVal   gint                    n         asInt}
}
# do unref

# #################  add-on dlr features supporting GI  ############################

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
# libgirepository functions are aliased into ::gi::$fnName
# features of the target native library are aliased into ::$libAlias, usually as Jim OO classes.
proc ::gi::declareCallToNative {scriptAction  giSpace  version  returnTypeDescrip  fnName  parmsDescrip} {
    set libAlias [giSpaceToLibAlias $giSpace]
    set fQal ::dlr::lib::${libAlias}::${fnName}::

    set err 0
    set tlbP [::gi::g_irepository_require  $::gi::repoP  $giSpace  $version  0  err]
    if {$err != 0} {
        error "GI namespace '$giSpace' not found."
    }
    if {$tlbP == 0} {
        error "GI typelib '$giSpace' not found."
    }

    # get GI callable info.
    set fnInfoP [::gi::g_irepository_find_by_name  $::gi::repoP  GLib  assertion_message]

    # query all metadata from GI callable.
#todo: implement declareCallToNative

    # pass callable info to prepMetaBlob

}

proc ::gi::declareSignalHandler {scriptAction  giSpace  version  returnTypeDescrip  fnName  parmsDescrip} {
    set libAlias [giSpaceToLibAlias $giSpace]
    set fQal ::dlr::lib::${libAlias}::${fnName}::

    set err 0
    set tlbP [::gi::g_irepository_require  $::gi::repoP  $giSpace  $version  0  err]
    if {$err != 0} {
        error "GI namespace '$giSpace' not found."
    }
    if {$tlbP == 0} {
        error "GI typelib '$giSpace' not found."
    }

    # get GI callable info.
    set fnInfoP [::gi::g_irepository_find_by_name  $::gi::repoP  GLib  assertion_message]

    # query all metadata from GI callable.
#todo: implement declareSignalHandler

    # pass callable info to prepMetaBlob
}


#todo: when declaring gtk classes, automatically fit them into Jim OO paradigm, all under ::Gtk

# #################  finish initializing gi package  ############################

set ::gi::repoP  [::gi::g_irepository_get_default]

#todo: move this feature into a new variant ::gi::loadLib
#todo: make ::gi::loadLib take the giSpace version number so it's not repeated in each declaration.
source  [file join [file dirname [info script]]  glib.tcl]
source  [file join [file dirname [info script]]  gtk.tcl]

set ::dlr::compiler  $::gi::oldCompiler

#todo: create a Jim class that holds a GObject pointer and its type info, and automatically verify that before passing pointer to another gnome func.
# and maybe holds lifetime info also, to help with automatic memory management.

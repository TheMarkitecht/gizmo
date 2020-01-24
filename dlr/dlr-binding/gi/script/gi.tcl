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

#todo: ::gi  aliases there for each GI call wrapped below.  and clean up the names.  create child namespaces e.g. ::gi::repository.

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

# #################  add-on dlr features for GI  ############################


#todo: when declaring gtk classes, fit them into Jim OO paradigm, all under ::gtk

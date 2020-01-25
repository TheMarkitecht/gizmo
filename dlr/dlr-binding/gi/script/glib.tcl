
# this file contains bindings for glib.

# load the library binding for testLib.  todo: delete this hack.  and its dir in dlr-binding as well. and the testLib-src symlink.
::dlr::loadLib  refreshMeta  testLib  [file join $::appDir .. dlr testLib-src testLib.so]

::gi::declareCallToNative  applyScript  testLib  {void}  assertGI  {
    {in     byPtr   ascii   a       asString}
    {in     byPtr   ascii   b       asString}
    {in     byVal   int     line    asInt}
    {in     byPtr   ascii   c       asString}
    {in     byPtr   ascii   d       asString}
}

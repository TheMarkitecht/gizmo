
# this file contains bindings for glib.

::gi::declareCallToNative  applyScript  GLib  2.0  {void}  assertion_message  {
    {in     byPtr   ascii   a       asString}
    {in     byPtr   ascii   b       asString}
    {in     byVal   int     line    asInt}
    {in     byPtr   ascii   c       asString}
    {in     byPtr   ascii   d       asString}
}

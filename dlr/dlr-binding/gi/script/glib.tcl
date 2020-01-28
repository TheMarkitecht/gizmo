
# this file contains bindings for glib.

alias  ::glib::free   dlr::native::giFreeHeap

::gi::declareStructType  applyScript  GLib  GError  {
    {GQuark     domain      asInt}
    {gint       code        asInt}
    {ptr        message     asInt}
}

proc ::glib::throwGError {errP} {
    if {$errP != 0} {
        set err [::dlr::struct::unpack-scriptPtr  asDict  ::dlr::lib::glib::struct::GError  $errP]
        error "GError: [::dlr::simple::ascii::unpack-scriptPtr-asString $err(message)]"
    }
}

::gi::declareCallToNative  applyScript  GLib  2.0  {void}  assertion_message  {
    {in     byPtr   ascii   a       asString}
    {in     byPtr   ascii   b       asString}
    {in     byVal   int     line    asInt}
    {in     byPtr   ascii   c       asString}
    {in     byPtr   ascii   d       asString}
}


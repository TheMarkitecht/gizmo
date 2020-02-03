
# this file contains bindings for glib.

alias  ::g::free   dlr::native::giFreeHeap

typedef  ptr  GType

::gi::declareStructType  convert  GLib  GError  {
    {GQuark     domain      asInt}
    {gint       code        asInt}
    {ptr        message     asInt}
}

proc ::g::checkGError {errP} {
    if {$errP != 0} {
        set err [::dlr::lib::g::struct::GError::unpack-scriptPtr-asDict  $errP]
        error "GError: [::dlr::simple::ascii::unpack-scriptPtr-asString $err(message)]"
    }
}

::gi::declareCallToNative  cmd  GLib  2.0  {void}  assertion_message  {
    {in     byPtr   ascii   a       asString}
    {in     byPtr   ascii   b       asString}
    {in     byVal   int     line    asInt}
    {in     byPtr   ascii   c       asString}
    {in     byPtr   ascii   d       asString}
}



# this file contains bindings for glib.

alias  ::g::free   dlr::native::giFreeHeap

::gi::typedef  ptr  GType

# this is required prior to declaring any whole space.
::gi::declareStructType  convert  GLib  Array

set disabled {
    ::dlr::declareStructType  convert  GLib  GError  {
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
}

::gi::declareFunction  cmd  GLib  {void}  assertion_message  {
    {in     byPtr   ascii   a       asString}
    {in     byPtr   ascii   b       asString}
    {in     byVal   int     line    asInt}
    {in     byPtr   ascii   c       asString}
    {in     byPtr   ascii   d       asString}
}


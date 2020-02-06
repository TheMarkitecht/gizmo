
# this file contains bindings for gtk.


::gi::declareCallToNative  cmd  Gtk  {void}  gtk_application_window_new  {
    {in     byVal   ptr   app       asInt}
}

::gi::declareCallToNative  cmd  Gtk  {void}  gtk_window_set_title  {
    {in     byVal   ptr     window      asInt}
    {in     byPtr   ascii   title       asString}
}

::gi::declareCallToNative  cmd  Gtk  {void}  gtk_window_set_default_size  {
    {in     byVal   ptr     window      asInt}
    {in     byVal   gint    width       asInt}
    {in     byVal   gint    height      asInt}
}

::gi::declareCallToNative  cmd  Gtk  {void}  gtk_widget_show_all  {
    {in     byVal   ptr     widget      asInt}
}

#::gi::declareClass  Gtk  GtkApplication  {}  {}
#::gi::declareMethods Gtk  GtkApplication  g_application_
# GtkApplication has a default instance.  that's unusual.
# it's called ::gio::GtkApplication::instance.  it's set by the gizmo C code.


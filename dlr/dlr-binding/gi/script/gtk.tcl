
# this file contains bindings for gtk.


::gi::declareCallToNative  applyScript  Gtk  3.0  {void}  gtk_application_window_new  {
    {in     byVal   ptr   app       asInt}
}
alias  ::gtk::gtk_application_window_new  ::dlr::lib::gtk::gtk_application_window_new::call
puts declared

::gi::declareCallToNative  applyScript  Gtk  3.0  {void}  gtk_window_set_title  {
    {in     byVal   ptr     window      asInt}
    {in     byPtr   ascii   title       asString}
}

::gi::declareCallToNative  applyScript  Gtk  3.0  {void}  gtk_window_set_default_size  {
    {in     byVal   ptr     window      asInt}
    {in     byVal   gint    width       asInt}
    {in     byVal   gint    height      asInt}
}

::gi::declareCallToNative  applyScript  Gtk  3.0  {void}  gtk_widget_show_all  {
    {in     byVal   ptr     widget      asInt}
}

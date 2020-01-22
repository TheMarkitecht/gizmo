/*
  gizmo
  Copyright 2020 Mark Hubbard, a.k.a. "TheMarkitecht"
  http://www.TheMarkitecht.com

  Project home:  http://github.com/TheMarkitecht/gizmo
  gizmo is a GNOME / GTK+ 3 windowing shell for Jim Tcl (http://jim.tcl.tk/)
  gizmo helps you quickly develop modern cross-platform GUI apps in Tcl.

  This file is part of gizmo.

  gizmo is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  gizmo is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with gizmo.  If not, see <https://www.gnu.org/licenses/>.
*/

#include <gtk/gtk.h>
#include <girepository.h>

#define JIM_EMBEDDED
#include <jim.h>

// links to libgtk-3.so.0.2404.1

Jim_Interp *itp;

//todo: bind g_free()

static void app_activate (GtkApplication* app,  gpointer user_data) {
    //todo: move to script.
    GtkWidget *window = gtk_application_window_new (app);
    gtk_window_set_title (GTK_WINDOW (window), "Window");
    gtk_window_set_default_size (GTK_WINDOW (window), 200, 200);
    gtk_widget_show_all (window);
}

static void app_open (GApplication *application,
               gpointer      files,
               gint          n_files,
               gchar        *hint,
               gpointer      user_data) {

    // run scripts named on command line.
    GFile** fArray = (GFile**)files;
    for (int i = 0; i < n_files; i++) {
        char* path = g_file_get_path(G_FILE(fArray[i]));
        if (Jim_EvalFileGlobal(itp, path) != JIM_OK) {
            Jim_MakeErrorMessage(itp);
            fprintf(stderr, "%s\n", Jim_GetString(Jim_GetResult(itp), NULL));
            gtk_main_quit(); //todo: use correct exit function, and set exit status
        }
        g_free(path);
    }

    // test call thru GI
    GIRepository *repository;
    GError *error = NULL;
    GIBaseInfo *base_info;
    GIArgument in_args[5];
    GIArgument retval;

    repository = g_irepository_get_default ();
    g_irepository_require (repository, "GLib", "2.0", 0, &error);
    if (error)
    {
      g_error ("ERROR: %s\n", error->message);
      return;
    }

    base_info = g_irepository_find_by_name (repository, "GLib", "assertion_message");
    if (!base_info)
    {
      g_error ("ERROR: %s\n", "Could not find GLib.warn_message");
      return;
    }

    in_args[0].v_pointer = (gpointer)"domain";
    in_args[1].v_pointer = (gpointer)"glib-print.c";
    in_args[2].v_int = 42;
    in_args[3].v_pointer = (gpointer)"main";
    in_args[4].v_pointer = (gpointer)"hello world";

    if (!g_function_info_invoke ((GIFunctionInfo *) base_info,
                               (const GIArgument *) &in_args,
                               5,
                               NULL,
                               0,
                               &retval,
                               &error))
    {
      g_error ("ERROR: %s\n", error->message);
      return;
    }

    g_base_info_unref (base_info);
}

int main (int argc, char **argv) {
    // prepare Jim interp.
    itp = Jim_CreateInterp();
    if (itp == NULL) {
        fprintf(stderr, "%s", "couldn't create interpreter\n");
        return 1;
    }
    Jim_RegisterCoreCommands(itp);
    Jim_InitStaticExtensions(itp);
    //todo: package provide gizmo, so dlr pkg can detect that, and enable declaring gnome calls.

    // prepare GNOME.
    GtkApplication *app;
    app = gtk_application_new ("org.gtk.example", G_APPLICATION_HANDLES_OPEN);
    g_signal_connect (app, "activate", G_CALLBACK (app_activate), NULL);
    g_signal_connect (app, "open", G_CALLBACK (app_open), NULL);
    int status = g_application_run (G_APPLICATION (app), argc, argv);

    // clean up.
    g_object_unref (app);
    Jim_FreeInterp(itp);
    return status;
}

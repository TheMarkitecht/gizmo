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

#include <jim.h>
#include "dlrNative.h"

// links to libgtk-3.so.0.2404.1

Jim_Interp *itp;

// from initgizmo.tcl
extern int Jim_initgizmoInit(Jim_Interp *interp);

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
}

int main (int argc, char **argv) {
    // prepare Jim interp.
    itp = Jim_CreateInterp();
    if (itp == NULL) {
        fprintf(stderr, "%s", "couldn't create interpreter\n");
        return 1;
    }
    Jim_SetVariableStrWithStr(itp, "jim::argv0", argv[0]);
    Jim_SetVariableStrWithStr(itp, "tcl_interactive", argc == 1 ? "1" : "0");
    Jim_RegisterCoreCommands(itp);
    Jim_InitStaticExtensions(itp);
    if (Jim_PackageProvide(itp, "gizmo", "1.0", JIM_ERRMSG))
        return JIM_ERR;
    if (Jim_initgizmoInit(itp) != JIM_OK) {
        Jim_MakeErrorMessage(itp);
        fprintf(stderr, "%s\n", Jim_GetString(Jim_GetResult(itp), NULL));
        return 1;
    }
    if (Jim_dlrNativeInit(itp) != JIM_OK) {
        fprintf(stderr, "%s", "couldn't init dlr\n");
        return 1;
    }

    // prepare GNOME.
    //todo: disable GNOME single-instance feature.
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

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

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define JIM_EMBEDDED
#include <jim.h>

// links to libgtk-3.so.0.2404.1

Jim_Interp *interp;

static void activate (GtkApplication* app,  gpointer user_data)
{
    GtkWidget *window = gtk_application_window_new (app);
    gtk_window_set_title (GTK_WINDOW (window), "Window");
    gtk_window_set_default_size (GTK_WINDOW (window), 200, 200);
    gtk_widget_show_all (window);
    
	/* Run a script. */
	if (Jim_Eval(interp, "puts {Jim ALIVE!!!}") == JIM_ERR) {
		Jim_MakeErrorMessage(interp);
		fprintf(stderr, "%s\n", Jim_GetString(Jim_GetResult(interp), NULL));
	}    
}

int main (int argc, char **argv)
{
	/* Create an interpreter. */
	interp = Jim_CreateInterp();
	assert(interp != NULL && "couldn't create interpreter");

	/* We register base commands, so that we actually implement Tcl. */
	Jim_RegisterCoreCommands(interp);

	/* And initialise any static extensions */
	Jim_InitStaticExtensions(interp);

    GtkApplication *app;
    int status;

    app = gtk_application_new ("org.gtk.example", G_APPLICATION_FLAGS_NONE);
    g_signal_connect (app, "activate", G_CALLBACK (activate), NULL);
    status = g_application_run (G_APPLICATION (app), argc, argv);
    g_object_unref (app);

	Jim_FreeInterp(interp);

    return status;
}

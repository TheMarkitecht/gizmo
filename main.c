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
#include <glib-object.h>
#include <gobject/gvaluecollector.h>

#include <jim.h>
#include "dlrNative.h"

//todo: eliminate this global; pass itp everywhere to allow for reentrance.
Jim_Interp* itp;
GtkWidget* mainWin;

// from initgizmo.tcl
extern int Jim_initgizmoInit(Jim_Interp *interp);

//todo: bind g_free()

static void app_activate (GtkApplication* app,  gpointer user_data) {
    //todo: move to script.
    mainWin = gtk_application_window_new (app);
    gtk_window_set_title (GTK_WINDOW (mainWin), "gizmo");
    gtk_window_set_default_size (GTK_WINDOW (mainWin), 200, 200);
    gtk_widget_show_all (mainWin);
}
/*
static void app_open (GApplication *application,
               gpointer      files,
               gint          n_files,
               gchar        *hint,
               gpointer      user_data) {

    // gtk doesn't signal 'activate' with one or more files given on command line.
    // in that case, activate on exactly the first 'open' for those.
    if (mainWin == NULL)
        app_activate(GTK_APPLICATION(application), NULL);

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
*/
void marshalMyClosure (GClosure *closure, GValue *return_value,
    guint n_param_values, const GValue *param_values,
    gpointer invocation_hint, gpointer marshal_data)
{
    // dlr conversions of GValues, in order of preference:
    // pointer asInt
    // integers asInt
    // floating point asDouble
    // bool asInt
    // all others ascii asString

    Jim_Obj* objv = Jim_NewListObj(itp, NULL, 0);
    Jim_ListAppendElement(itp, objv, Jim_NewStringObj(itp, "::gi::handleSignal", -1));
    //todo: extract signal name.

    printf("n_param_values=%u\n", n_param_values);
    const GValue* gvP = param_values;
    for (guint i = 0; i < n_param_values; i++, gvP++) {
        Jim_Obj* o = NULL;
        printf("type=%s\n", G_VALUE_TYPE_NAME(gvP));
        //todo: skip all these runtime checks by configuring each conversion in advance, from GI metadata.
        GType typ = G_VALUE_TYPE(gvP); // probably accessible by g_value_get_gtype() also.
        if (G_TYPE_IS_CLASSED(typ) || G_VALUE_HOLDS_POINTER(gvP)) {
            printf("    pointer\n");
            o = Jim_NewIntObj(itp, (jim_wide)g_value_peek_pointer(gvP));
        } else if (G_VALUE_HOLDS_INT(gvP)) {
            printf("    int\n");
            o = Jim_NewIntObj(itp, (jim_wide)g_value_get_int(gvP));
        } else {
/* this works but don't want it here.
            printf("    other\n");
            GValue b = G_VALUE_INIT;
            g_value_init (&b, G_TYPE_STRING);
            g_return_if_fail(g_value_transform(gvP, &b));
            //todo: extract string length from GValue struct to avoid paying for another length scan here.
            o = Jim_NewStringObj(itp, g_value_get_string(&b), -1);
*/
        }
        if (o) Jim_ListAppendElement(itp, objv, o);
    }
    //todo: cope with array.
    // it's not a GArray.
    // G_VALUE_TYPE_NAME says it's a gchararray, which is typedef gchar*, a string.  wrong.
    // https://developer.gnome.org/gio/stable/GApplication.html#GApplication-open
    // docs say it's a C array of GFile's.

    //todo: quit testing with 'open' and change to some other signal that is visible in gi; a candidate for automatic binding.
    // in fact it is visible, in the Gio giSpace instead of Glib.

    // extract numFiles.
    GValue numFilesV = G_VALUE_INIT;
    g_value_init (&numFilesV, G_TYPE_INT);
    g_return_if_fail(g_value_transform(param_values + 2, &numFilesV) > 0);
    gint numFiles = g_value_get_int (&numFilesV);
    printf ("numFiles=%d\n", numFiles);

    // extract filenames.
    Jim_Obj* fnList = Jim_NewListObj(itp, NULL, 0);
    GFile** files = g_value_peek_pointer (param_values + 1);
    for (int i = 0; i < numFiles; i++) {
        char* path = g_file_get_path(G_FILE(files[i]));
        printf("file=%s\n", path);

        Jim_ListAppendElement(itp, fnList, Jim_NewStringObj(itp, path, -1));

        g_free(path);
    }
    Jim_ListAppendElement(itp, objv, fnList);

    // using the list's internalRep should run slightly faster than Jim_EvalObjList().
    int result = Jim_EvalObjVector(itp, objv->internalRep.listValue.len, objv->internalRep.listValue.ele);
    g_return_if_fail(result == JIM_OK || result == JIM_RETURN);
    //todo: marshal interp's return value back to *return_value.
}

// GObject closure
typedef struct _MyClosure MyClosure;
struct _MyClosure
{
  GClosure closure;
  // extra data goes here
};

/*
static void my_closure_finalize (gpointer  notify_data, GClosure *closure)
{
  MyClosure *my_closure = (MyClosure *)closure;
  // free extra data here
}  */

MyClosure *my_closure_new (gpointer data)
{
  GClosure *closure;
  MyClosure *my_closure;

  closure = g_closure_new_simple (sizeof (MyClosure), data);
  my_closure = (MyClosure *) closure;

g_closure_set_marshal(closure, marshalMyClosure);

  // initialize extra data here

  //g_closure_add_finalize_notifier (closure, notify_data, my_closure_finalize);
  return my_closure;
}

int main (int argc, char **argv) {
    const int MAIN_ERROR_EXIT_STATUS = 255;

    // prepare GNOME.
    GtkApplication* app = gtk_application_new ("org.gizmo",
        G_APPLICATION_HANDLES_OPEN | G_APPLICATION_NON_UNIQUE);
    printf("app=%p\n", app);
    g_signal_connect (app, "activate", G_CALLBACK (app_activate), NULL);
    //g_signal_connect (app, "open", G_CALLBACK (app_open), NULL);


    MyClosure* clos = my_closure_new(NULL);
    // most signals are described in gi.  this one is not??
    if (g_signal_connect_closure (app, "open", (GClosure*)clos, 0) == 0) {
        fprintf(stderr, "%s", "couldn't connect to 'open' signal\n");
        return MAIN_ERROR_EXIT_STATUS;
    }



    // prepare Jim interp.
    itp = Jim_CreateInterp();
    if (itp == NULL) {
        fprintf(stderr, "%s", "couldn't create interpreter\n");
        return MAIN_ERROR_EXIT_STATUS;
    }
    Jim_SetVariableStrWithStr(itp, "jim::argv0", argv[0]);
    Jim_SetVariableStrWithStr(itp, "tcl_interactive", argc == 1 ? "1" : "0");
    Jim_RegisterCoreCommands(itp);
    Jim_InitStaticExtensions(itp);
    if (Jim_dlrNativeInit(itp) != JIM_OK) {
        fprintf(stderr, "%s", "couldn't init dlr\n");
        return MAIN_ERROR_EXIT_STATUS;
    }
    Jim_SetVariableStr(itp, "gtk::appP", Jim_NewIntObj(itp, (jim_wide)app));

    // run gizmo init script.
    if (Jim_initgizmoInit(itp) != JIM_OK) {
        Jim_MakeErrorMessage(itp);
        fprintf(stderr, "%s\n", Jim_GetString(Jim_GetResult(itp), NULL));
        return MAIN_ERROR_EXIT_STATUS;
    }
    // determine process exit status.
    //todo: remove if g_application_run will be called from C.
    //jim_wide status = MAIN_ERROR_EXIT_STATUS;
    //Jim_GetWide(itp, Jim_GetResult(itp), &status);

    // run GNOME event loop.  wait for it to exit.
    // scripts named on command line run at this time.
    int status = g_application_run(G_APPLICATION (app), argc, argv);

    // clean up.
    Jim_FreeInterp(itp);
    g_object_unref(app);

    return (int)status;
}

#  gizmo
#  Copyright 2020 Mark Hubbard, a.k.a. "TheMarkitecht"
#  This file is part of gizmo.  See copyright notice in gizmo's main.c file.

proc ::jim::neutralizeDirSeparators {path} {
    # convert the given path from platform-specific path separators to platform-neutral ones.
    return [string map [list $::tcl_platform(dirSeparator) / ] $path]
}

proc _gizmo_init {} {
    rename _gizmo_init {}
    global jim::exe jim::argv0 tcl_interactive auto_path tcl_platform

    set tcl_platform(dirSeparator) $( $tcl_platform(platform) eq "windows" ? "\\" : "/" )

    set jim::argv0 [::jim::neutralizeDirSeparators $jim::argv0]

    # set up the result of [info nameofexecutable] now, before a possible [cd]
    if {[exists jim::argv0]} {
        if {[string match "*/*" $jim::argv0]} {
            set jim::exe [file join [pwd] $jim::argv0]
        } else {
            # search the environment's executable paths, to guess which one the interp launched from.
            foreach path [split [env PATH ""] $tcl_platform(pathSeparator)] {
                set exec [file join [pwd] [::jim::neutralizeDirSeparators $path] $jim::argv0]
                if {[file executable $exec]} {
                    set jim::exe $exec
                    break
                }
            }
        }
    }

    # build up auto_path
    lappend p {*}[split [env JIMLIB {}] $tcl_platform(pathSeparator)]
    if {[exists jim::exe]} {
        lappend p [file dirname $jim::exe]
    }
    lappend p {*}$auto_path
    set auto_path $p

    return ""
}

_gizmo_init

#todo: source stdlib.tcl here.

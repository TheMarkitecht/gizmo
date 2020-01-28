# gizmo

Project home:  [http://github.com/TheMarkitecht/gizmo](http://github.com/TheMarkitecht/gizmo)

Legal stuff:  see below.

---

## Introduction:

**gizmo** is a [GNOME / GTK+ 3](http://developer.gnome.org) windowing environment for [Jim Tcl](http://jim.tcl.tk/), the small-footprint Tcl interpreter.
**gizmo** helps you quickly develop and execute modern cross-platform GUI apps in Tcl.  **gizmo** is suitable for the desktop, and also for IoT devices and other small embedded computing platforms, if they need a GUI and have enough RAM to run GTK+.

**gizmo** uses [dlr](http://github.com/TheMarkitecht/dlr) to bind your Jim scripts to [libgirepository](http://developer.gnome.org/gi/stable).  Then scripts can show their own GTK+ user interface, without writing any C/C++ code if you don't want to.  Along the way, **dlr** also helps scripts call the many other native libraries in the world: those that expose GNOME GObject interfaces, and those that don't, such as libc.

**gizmo** is so named because it begins with GI - the [GObject Introspection](https://gi.readthedocs.io/en/latest/index.html) framework.

## Features of This Version:

* This is the proof-of-concept version.
* GLib and GI binding scripts in **gizmo** also work in an ordinary jimsh with dlr.  Just avoid Gtk since there's no GUI linkage in jimsh with dlr.
* Ultra-simple build process.
* Designed for Jim 0.79 on GNU/Linux for amd64 architecture (includes Intel CPU's).
* Tested on Debian 10.0 with libffi6-3.2.1-9, libgirepository-1.0-1 (1.58.3-2), and libgtk-3-0 (3.24.5-1).
* Might work well on ARM too.  Drop me a line if you've tried it!

## Requirements:

* Jim 0.79 or later
* Latest [dlr](http://github.com/TheMarkitecht/dlr) source tree
* gcc (tested with gcc 8.3.0)

## Building:

See [build](build) script.

## Future Direction:

* Hook and handle GObject signals in script apps.
* Test on ARM embedded systems.
* Speed improvements?

## Legal stuff:
```
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
```

See [COPYING.LESSER](COPYING.LESSER) and [COPYING](COPYING).

## Contact:

Send donations, praise, curses, and the occasional question to: `Mark-ate-TheMarkitecht-dote-com`

## Final Word:

I hope you enjoy this software.  If you enhance it, port it to another environment,
or just use it in your project etc., by all means let me know.

>  \- TheMarkitecht

---

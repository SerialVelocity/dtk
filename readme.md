# Dtk

This is a D wrapper of the Tcl/Tk graphics library. It's based on Tcl/Tk v8.6.0.0.

**Note:** The project is a work-in-progress and is in pre-alpha quality condition. Do not use yet.

A previous porting attempt was lysevi's [dkinter](https://github.com/lysevi/dkinter) project, which has been stale for many years.

Dtk uses the Tcl interpreter to invoke GUI-related commands. Although Dtk partially uses the Tk C API, most of its functionality is implemented by using the Tcl interpreter. The Tcl/Tk C API does not expose functionality to various high-level tk and ttk (themed tk) widgets.

Currently it's only tested on Windows 7.

## Building

Make sure you're using the latest compiler. Sometimes that even means using the latest git-head version
(sorry about that).

Run the `build.bat` file to both run the unittests and generate a static library in the `bin` subfolder.

## Links

ActiveTcl Tcl/Tk distribution: http://www.activestate.com/activetcl/downloads

Tcl v8.6 reference links: http://www.tcl.tk/man/tcl8.6/
Tcl v8.6 Tcl commands: http://www.tcl.tk/man/tcl8.6/TclCmd/contents.htm
Tcl v8.6 Tk commands: http://www.tcl.tk/man/tcl8.6/TkCmd/contents.htm
Tcl Wiki book: http://en.wikibooks.org/wiki/Tcl_Programming/Tk

## License

Distributed under the Boost Software License, Version 1.0.
See accompanying file LICENSE_1_0.txt or copy [here][BoostLicense].

[BoostLicense]: http://www.boost.org/LICENSE_1_0.txt

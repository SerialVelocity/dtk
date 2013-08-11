/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.app;

import std.stdio;
import std.c.stdlib;

import std.exception;
import std.string;
import std.conv;
import std.path;

import dtk.event;
import dtk.loader;
import dtk.types;
import dtk.widget;
import dtk.window;

/** The main dtk application. Once instantiated a main window will be created. */
final class App
{
    /** Create the app and a main window. */
    this()
    {
        _interp = enforce(Tcl_CreateInterp());

        enforce(Tcl_Init(_interp) == TCL_OK, to!string(_interp.result));
        enforce(Tk_Init(_interp) == TCL_OK, to!string(_interp.result));

        _window = new Window(enforce(Tk_MainWindow(_interp)));
    }

    version(unittest)
    {
        import std.datetime;

        void run(Duration runTime)
        {
            auto displayTimer = StopWatch(AutoStart.yes);

            auto runTimeDur = cast(TickDuration)runTime;
            auto runTimeWatch = StopWatch(AutoStart.yes);

            while (runTimeWatch.peek < runTimeDur)
            {
                if (displayTimer.peek > cast(TickDuration)(1.seconds))
                {
                    displayTimer.reset();
                    auto timeLeft = runTimeDur - runTimeWatch.peek;
                    stderr.writefln("-- Time left: %s seconds.", (runTimeDur - runTimeWatch.peek).seconds);
                }

                // event found, add some idle time to allow processing
                if (Tcl_DoOneEvent(TCL_DONT_WAIT) != 0)
                {
                    runTime += 200.msecs;
                    runTimeDur = cast(TickDuration)runTime;

                    auto durSecs = runTimeDur.seconds;
                    auto durMsecs = runTimeDur.msecs - (durSecs * 1000);
                    stderr.writefln("-- Idle time increased to: %s seconds, %s msecs.", durSecs, durMsecs);
                }
            }

            this.exit();
        }
    }

    /** Start the App event loop. */
    void run()
    {
        scope(exit)
            this.exit();

        Tk_MainLoop();
    }

    /** Return the main app window. */
    @property Window mainWindow()
    {
        return _window;
    }

    public static string evalFmt(T...)(string fmt, T args)
    {
        return eval(format(fmt, args));
    }

    /** Evaluate any Tcl command and return its result. */
    public static string eval(string cmd)
    {
        stderr.writefln("tcl_eval %s", cmd);
        Tcl_Eval(_interp, cast(char*)toStringz(cmd));
        return to!string(_interp.result);
    }

private:
    void exit()
    {
        Tcl_DeleteInterp(_interp);
    }

package:
    /** Only one interpreter is allowed. */
    __gshared Tcl_Interp* _interp;

private:
    Window _window;
}

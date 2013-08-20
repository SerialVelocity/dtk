/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.widgets.combobox;

import std.conv;
import std.exception;
import std.range;
import std.string;

import dtk.app;
import dtk.event;
import dtk.signals;
import dtk.types;
import dtk.utils;
import dtk.options;

import dtk.widgets.button;
import dtk.widgets.widget;

///
class Combobox : Widget
{
    ///
    this(Widget master)
    {
        super(master, TkType.combobox);

        _varName = this.createTracedTaggedVariable(EventType.TkComboboxChange);
        this.setOption("textvariable", _varName);
    }

    /** Get the currently selected combobox value. */
    @property string value()
    {
        return this.evalFmt("%s get", _name);
    }

    /** Set the combobox value. */
    @property void value(string newValue)
    {
        this.evalFmt("%s set %s", _name, newValue);
    }

    /** Get the values in this combobox. */
    @property string[] values()
    {
        return this.getOption!string("values").split(" ");
    }

    /** Set the values for this combobox. */
    @property void values(string[] newValues)
    {
        this.setOption("values", newValues.join(" "));
    }

    /** Allow or disallow inputting custom values to this combobox. */
    @property void readOnly(bool doDisableWrite)
    {
        this.setState(doDisableWrite ? "readonly" : "!readonly");
    }

private:
    string _varName;
}
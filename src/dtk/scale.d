/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.scale;

import std.conv;
import std.string;
import std.range;

import dtk.app;
import dtk.event;
import dtk.geometry;
import dtk.options;
import dtk.utils;
import dtk.widget;

///
class Scale : Widget
{
    ///
    this(Widget master, Orientation orientation, int length, float minValue = 0.0, float maxValue = 100.0)
    {
        DtkOptions options;
        options["orient"] = to!string(orientation);
        options["length"] = to!string(length);
        options["from"] = to!string(minValue);
        options["to"] = to!string(maxValue);

        _minValue = minValue;
        _maxValue = maxValue;
        super(master, TkType.scale, options);

        _varName = this.createTracedTaggedVariable(EventType.TkScaleChange);
        this.setOption("variable", _varName);
    }

    /** Get the current value of the scale. */
    @property float value()
    {
        string res = this.getVar!string(_varName);

        if (res.empty)
            return 0.0;

        return to!float(res);
    }

    /**
        Set the current value of the scale.
        This should be a value between minValue and maxValue set in
        the constructor.
    */
    @property void value(float newValue)
    {
        this.setVar(_varName, newValue);
    }

    /** Get the minimum value that was set in the constructor. */
    @property float minValue()
    {
        return _minValue;
    }

    /** Get the maximum value that was set in the constructor. */
    @property float maxValue()
    {
        return _maxValue;
    }

private:
    float _minValue;
    float _maxValue;
    string _varName;
}
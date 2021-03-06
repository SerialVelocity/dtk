/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.widgets.spinbox;

import dtk.app;
import dtk.dispatch;
import dtk.event;
import dtk.geometry;
import dtk.imports;
import dtk.interpreter;
import dtk.signals;
import dtk.types;
import dtk.utils;

import dtk.widgets.widget;

///
abstract class SpinboxBase : Widget
{
    ///
    package this(Widget parent, WidgetType widgetType, EventType eventType)
    {
        super(parent, TkType.spinbox, widgetType);

        _varName = makeVar();
        tclEvalFmt(`trace add variable %s write { %s %s %s }`, _varName, _dtkCallbackIdent, eventType, _name);
        this.setOption("textvariable", _varName);
    }

    /** Check the wrapping mode for this spinbox. */
    @property bool wrap()
    {
        return this.getOption!int("wrap") == 1;
    }

    /**
        Set the wrapping mode for this spinbox. If set to true,
        values will wrap around when the spinbox goes beyond the
        starting or ending value.
    */
    @property void wrap(bool doWrap)
    {
        this.setOption("wrap", doWrap ? 1 : 0);
    }

private:
    string _varName;
}

///
class ScalarSpinbox : SpinboxBase
{
    ///
    this(Widget parent, float minValue = 0.0, float maxValue = 100.0)
    {
        minValue.checkFinite();
        maxValue.checkFinite();
        _minValue = minValue;
        _maxValue = maxValue;
        super(parent, WidgetType.scalar_spinbox, EventType.scalar_spinbox);

        this.setOption("from", minValue);
        this.setOption("to", maxValue);
    }

    /**
        Signal emitted when an item in the scalar spinbox is selected.
    */
    public Signal!ScalarSpinboxEvent onScalarSpinboxEvent;

    /** Get the current value of the spinbox. */
    @property float value()
    {
        string res = tclGetVar!string(_varName);

        if (res.empty)
            return float.init;

        return to!float(res);
    }

    /**
        Set the current value of the spinbox.
        This should be a value between minValue and maxValue set in
        the constructor.
    */
    @property void value(float newValue)
    {
        newValue.checkFinite();
        tclSetVar(_varName, newValue);
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
}

///
class ListSpinbox : SpinboxBase
{
    ///
    this(Widget parent, string[] values)
    {
        super(parent, WidgetType.list_spinbox, EventType.list_spinbox);
        this.setOption("values", values);
    }

    /**
        Signal emitted when an item in the list spinbox is selected.
    */
    public Signal!ListSpinboxEvent onListSpinboxEvent;

    /** Get the values in this spinbox. */
    @property string[] values()
    {
        return this.getOption!(string[])("values");
    }

    /** Set the values in this spinbox. */
    @property void values(string[] newValues)
    {
        this.setOption("values", newValues);
    }

    /** Get the current value of the spinbox. */
    @property string value()
    {
        return tclGetVar!string(_varName);
    }

    /**
        Set the current value of the spinbox.
    */
    @property void value(string newValue)
    {
        tclSetVar(_varName, newValue);
    }
}

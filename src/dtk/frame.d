/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.frame;

import std.conv;
import std.string;

import dtk.geometry;
import dtk.utils;
import dtk.options;
import dtk.widget;

enum BorderStyle
{
    Invalid,  // sentinel

    flat,   ///
    groove, ///
    raised, ///
    ridge,  ///
    solid,  ///
    sunken, ///
}

class Frame : Widget
{
    this(Widget master, Padding padding)
    {
        DtkOptions options;
        options["padding"] = padding.toString;
        super(master, "ttk::frame", options);

        this.setOption("borderwidth", 2);
        this.setOption("relief ", "sunken");
    }

    /** Get the current width of the border. */
    @property int borderWidth()
    {
        return this.getOption!int("borderwidth");
    }

    /** Set the desired width of the border. */
    @property void borderWidth(int newBorderWidth)
    {
        this.setOption("borderwidth", newBorderWidth);
    }

    /** Get the current border style. */
    @property BorderStyle borderStyle()
    {
        return this.getOption!BorderStyle("relief");
    }

    /** Set a new border style. */
    @property void borderStyle(BorderStyle newBorderStyle)
    {
        this.setOption("relief", newBorderStyle.text);
    }

    /**
        Set a requested size for this frame. Note that if the pack, grid, or
        other geometry managers are used to manage the children of the frame
        the geometry manager's requested size will normally take precedence
        over the frame widget's size.

        Todo: pack propagate and grid propagate can be used to change this.
    */
    @property void size(Size newSize)
    {
        this.setOption("width", newSize.width);
        this.setOption("height", newSize.height);
    }

    /**
        Get the current requested Frame size. This often returns Size(0, 0)
        since a frame typically doesn't explicitly request a specific size.
    */
    @property Size size()
    {
        Size result;
        result.width = this.getOption!int("width");
        result.height = this.getOption!int("height");
        return result;
    }
}
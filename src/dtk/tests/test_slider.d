/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.tests.test_slider;

version(unittest):
version(DTK_UNITTEST):

import core.thread;

import std.conv;
import std.range;
import std.stdio;
import std.string;

import dtk;

import dtk.tests.globals;

unittest
{
    auto testWindow = new Window(app.mainWindow, 200, 200);
    testWindow.position = Point(500, 500);

    auto slider = new Slider(app.mainWindow, Angle.horizontal, 200);
    slider.pack();

    assert(slider.minValue > -1.0 && slider.minValue < 1.0);
    assert(slider.maxValue > 99.0 && slider.maxValue < 101.0);

    assert(slider.value == 0.0);
    slider.value = 50.0;

    size_t callCount;
    size_t expectedCallCount;

    float value = 0;

    slider.onSliderEvent ~= (scope SliderEvent event)
    {
        assert(event.slider is slider);
        assert(event.slider.value > value - 1 && event.slider.value < value + 1);
        ++callCount;
    };

    value = 10;
    slider.value = 10;
    ++expectedCallCount;

    assert(callCount == expectedCallCount, format("%s != %s", callCount, expectedCallCount));

    app.testRun();
}

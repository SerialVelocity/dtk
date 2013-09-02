/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.event;

import core.stdc.config : c_ulong;

import std.array;
import std.conv;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;

import dtk.geometry;
import dtk.keymap;
import dtk.signals;
import dtk.utils;

import dtk.widgets.widget;

/// The type of the $(D timeMsec) field in an event.
public alias TimeMsec = c_ulong;

/**
    All the possible event types. If the event is a custom user event type,
    the event type will equal to EventType.user.
*/
enum EventType
{
    /** sentinel, an EventType should never be left default-initialized. */
    invalid,

    /**
        Any user-derived events will automatically have this event type set.
        The $(D userType) field can be used for user-defined tagging of the event.
    */
    user,

    /**
        Mouse event, e.g. a mouse moved, its wheel was turned,
        or one of its buttons was clicked.
    */
    mouse,

    /**
        Keyboard event, e.g. a key or key sequence was pressed or released,
        or held long enough to trigger a key hold event.
    */
    keyboard,
}

/**
    Each event is traveling in a direction, either from the root window of
    the target child towards the target child widget (sinking), or in the
    opposite direction (bubbling).
*/
enum EventTravel
{
    ///
    invalid,  // sentinel

    /// The event is going through the target widget's filter list.
    filtering,

    /// The event is sinking from the toplevel parent of this widget, towards the widget.
    sinking,

    /// The event has reached its target widget, and is now being handled by either
    /// onEvent and/or one of its specific event handlers, such as onKeyboardEvent.
    target,

    /// The event is bubbling upwards towards the toplevel parent of this widget.
    bubbling,


    // direct,  // todo
}

// All standard event types are listed here, in the same order as EventType.
private alias EventClassMap = TypeTuple!(Event, Event, MouseEvent, KeyboardEvent);

/**
    Return the Event class type that matches the EventType specified.
    If the event type is a user event, the $(D Event) base class is returned.
*/
template toEventClass(EventType type)
{
    static assert(type != EventType.invalid,
        "Cannot retrieve event class type from uninitialized event type.");

    alias toEventClass = EventClassMap[cast(size_t)type];
}

///
unittest
{
    static assert(is(toEventClass!(EventType.user) == Event));
    static assert(is(toEventClass!(EventType.mouse) == MouseEvent));
    static assert(is(toEventClass!(EventType.keyboard) == KeyboardEvent));
}

/** The root class of all event types. */
class Event
{
    /**
        This base class constructor is only called for user-derived events.
        It ensures the event type is initialized as a user event.

        It can optionally take a user event type tag.
    */
    this(Widget targetWidget, long userType = 0, TimeMsec timeMsec = 0)
    {
        this.userType = userType;
        this(targetWidget, EventType.user, timeMsec);
    }

    package this(Widget targetWidget, EventType type, TimeMsec timeMsec)
    {
        this.type = type;
        this.userType = 0;
        this.timeMsec = timeMsec;
        _targetWidget = targetWidget;
    }

    /**
        Get the timestamp when the event occured.
        The returned type is a $(D core.time.Duration) type.
        The time is relative to when the system started.
    */
    @property auto time()()
    {
        import core.time;
        return timeMsec.dur!"msecs";
    }

    /**
        The timestamp in milliseconds when the event occurred.
        The time is relative to when the system started.
        Use $(D time) to get a $(D Duration) type.
    */
    public const(TimeMsec) timeMsec;

    /**
        The type of this event. Use this to quickly determine the dynamic type of the event.
        You can use the $(D toEventClass) to get the class type based on a known event type.
    */
    public const(EventType) type;

    /**
        A user-defined value which is typically usedto tag the dynamic type of the user event.
        This field is empty when the event is not a user-event, but otherwise can equal any
        value the user specifies.
    */
    public const(long) userType;

    /**
        Event handlers can set this field to true to  stop the event propagation mechanism.
        An event which is currently sinking or bubbling will stop traveling,
        and other event handlers will not be invoked for this event.
    */
    public bool handled = false;

    /**
        Get the target widget of this event.
    */
    @property Widget widget()
    {
        return _targetWidget;
    }

    /** Return the current travel direction of this event. */
    public @property EventTravel eventTravel()
    {
        return _eventTravel;
    }

    /** Output the string representation of this event. */
    public void toString(scope void delegate(const(char)[]) sink) { }

    /**
        Used for reusability in derived classes, where we want the fields
        but not the class name in the output.
    */
    final protected void toStringMembers(scope void delegate(const(char)[]) sink)
    {
        sink(to!string(widget));
        sink(", ");
        sink(to!string(timeMsec));
    }

package:

    /**
        The target widget for the event. Note that this isn't a const public field, since
        we want to allow modification to the widget, but disallow modification to the
        event object itself. Hence the property getter above.
    */
    Widget _targetWidget;

    /** The current travel direction of the event. */
    EventTravel _eventTravel;
}

/**
    A set of possible mouse actions.
    Press and release actions include any mouse
    button, such as the middle or wheel button.
*/
enum MouseAction
{
    /** One of the mouse buttons was pressed. */
    press,

    /** One of the mouse buttons was released. */
    release,

    /** Convenience - equal to $(D press). */
    click = press,

    /** One of the mouse buttons was clicked twice in rapid succession. */
    double_click,

    /** One of the mouse buttons was clicked three times in rapid succession. */
    tripple_click,

    /** One of the mouse buttons was clicked four times in rapid succession. */
    quadruple_click,

    /**
        The mouse wheel was moved. See the $(D wheelStep) field to determine
        the direction the mouse wheel was moved in.

        $(BLUE Note): When the wheel is pressed as a mouse button,
        the action will equal $(D press), not $(D wheel).
    */
    wheel,

    /** The mouse was moved. */
    move,
}

/**
    A set of possible mouse buttons.
*/
enum MouseButton
{
    /** The left mouse button. */
    button1,

    /** Convenience - equal to $(D button1). */
    left = button1,

    /** The middle mouse button. */
    button2,

    /** Convenience - equal to $(D button2). */
    middle = button2,

    /** The right mouse button. */
    button3,

    /** Convenience - equal to $(D button3). */
    right = button3,
}

//~ enum ShiftMask   = (1<<0);
//~ enum LockMask    = (1<<1);
//~ enum ControlMask = (1<<2);
//~ enum Mod1Mask    = (1<<3);
//~ enum Mod2Mask    = (1<<4);
//~ enum Mod3Mask    = (1<<5);
//~ enum Mod4Mask    = (1<<6);
//~ enum Mod5Mask    = (1<<7);

//~ enum META_MASK = (AnyModifier<<1);
//~ enum ALT_MASK = (AnyModifier<<2);
//~ enum EXTENDED_MASK = (AnyModifier<<3);

private enum AnyModifier = 1 << 15;
//~ private enum EXTENDED_MASK = 1 << 15;

/**
    A set of possible key modifiers.
    These are special keys such as the control
    and alt keys.

    todo: add bit checking for these, which means we have to init them
    properly. See test in d_code somewhere
*/
// major todo: the keysym already defines alt_l and alt_r, this enum should just
// be a subgroup of that enum.
// major todo: remove these bit initializers, and instead use a helper function to
// extract this info when we need it (only for mice during %S substitution, because
// otherwise we already have the %K substitution).
enum KeyMod
{
    none = 0,

    /** Control key. */
    control = 1 << 2,

    /** Alt key. */
    alt = AnyModifier << 2,

    /** Convenience for OSX - equal to $(D alt). */
    option = alt,

    ///
    shift = 1 << 0,

    // todo: when caps lock is turned off, lock is set.
    // we can probably tell then if it's on or off.

    ///
    lock = 1 << 1,

    /**
        The meta key is present on special keyboards,
        such as the MIT keyboard.
        See: http://en.wikipedia.org/wiki/Meta_key
    */
    meta = AnyModifier << 1,
}

class MouseEvent : Event
{
    MouseAction action;

    this()
    {
        // todo: we should pass a widget
        super(null, EventType.mouse);
    }
}

class KeyboardEvent : Event
{
    this(Widget widget, KeySym keySym, KeyMod keyMod, TimeMsec timeMsec)
    {
        super(widget, EventType.keyboard, timeMsec);
        this.keySym = keySym;
        this.keyMod = keyMod;
    }

    ///
    override void toString(scope void delegate(const(char)[]) sink)
    {
        sink(__traits(identifier, typeof(this)));
        sink("(");

        foreach (i, val; this.tupleof)
        {
            sink(to!string(val));
            sink(", ");
        }

        Event.toStringMembers(sink);
        sink(")");
    }

    /// The key symbol that was pressed or released
    const(KeySym) keySym;

    /**
        A bit mask of all key modifiers that were
        held while keySym was pressed or released.

        Examples:
        -----
        // test if control was held
        if (keyMod & KeyMod.control) { }

        // test if both control and alt were held at the same time
        if (keyMod & (KeyMod.control | KeyMod.alt)) { }
        -----
    */
    const(KeyMod) keyMod;
}

/** Old code below */

//~ import dtk.widgets.entry;

/** Tk event types. */
package enum TkEventType
{
    Invalid,  // sentinel
    Activate,
    Destroy,
    Map,
    ButtonPress,
    // Button,
    Enter,
    MapRequest,
    ButtonRelease,
    Expose,
    Motion,
    Circulate,
    FocusIn,
    MouseWheel,
    CirculateRequest,
    FocusOut,
    Property,
    Colormap,
    Gravity,
    Reparent,
    Configure,
    KeyPress,
    Key,
    ResizeRequest,
    ConfigureRequest,
    KeyRelease,
    Unmap,
    Create,
    Leave,
    Visibility,
    Deactivate,

    TkButtonPush,
    TkCheckButtonToggle,
    TkRadioButtonSelect,
    TkComboboxChange,
    TkTextChange,
    TkValidate,
    TkFailedValidation,
    TkListboxChange,
    TkProgressbarChange,
    TkScaleChange,
    TkSpinboxChange,
    TkMenuItemSelect,
    TkCheckMenuItemToggle,
    TkRadioMenuSelect,
}

///
enum ValidationType
{
    preInsert,
    preDelete,
    revalidate
}

ValidationType toValidationType(int input)
{
    switch (input) with (ValidationType)
    {
        case  1: return preInsert;
        case  0: return preDelete;
        case -1: return revalidate;
        default: assert(0, format("Unhandled validation type: '%s'", input));
    }
}

//~ ///
//~ struct ValidateEvent
//~ {
    //~ /** type of validation action. */
    //~ ValidationType type;

    //~ /** index of character in string to be inserted/deleted, if any, otherwise -1. */
    //~ sizediff_t charIndex;

    //~ /**
        //~ In prevalidation, the new value of the entry if the edit is accepted.
        //~ In revalidation, the current value of the entry.
    //~ */
    //~ string newValue;

    //~ /** The current value of entry prior to editing. */
    //~ string curValue;

    //~ /** The text string being inserted/deleted, if any, {} otherwise. */
    //~ string changeValue;

    //~ /** The current value of the validation mode for this widget. */
    //~ ValidationMode validationMode;

    //~ /**
        //~ The validation condition that triggered the callback.
        //~ If the validationMode is set to $(B all), validationCondition
        //~ will contain the actual condition that triggered the
        //~ validation (e.g. $(B key)).
    //~ */
    //~ ValidationMode validationCondition;
//~ }

//~ ///
//~ struct Event
//~ {
    //~ EventType type;

    //~ int x;
    //~ int y;
    //~ int keycode;
    //~ int character;
    //~ int width;
    //~ int height;
    //~ int root_x;
    //~ int root_y;
    //~ string state;  // e.g. toggle state
    //~ ValidateEvent validateEvent;
//~ }

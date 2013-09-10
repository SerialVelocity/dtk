/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.signals;

import std.algorithm;
import std.container;
//~ import std.functional;
//~ import std.range;
import std.traits;
import std.typecons;
//~ import std.exception;
//~ import std.stdio;
//~ import std.typetuple;

import dtk.event;

/**
    Some of the Signal code is based off of Johannes Pfau's
    signals module, which he introduced here: https://gist.github.com/1194497
*/

/**
    A single event handler. A user can assign a function or delegate
    event handler, a class with an $(D opCall) function, or a struct
    pointer with an $(D opCall) function. The event handler must take
    a single $(D EventClass) parameter with the $(D scope) storage class.

    $(D EventClass) is typically $(D Event) or one of its derived classes.

    Multiple assignment is possible, however each new assignment will
    remove any existing handler.

    Assigning $(D null) or calling $(D clear) will remove the event
    handler, and it will no longer be invoked when $(D call) is called.
*/
struct EventHandler(EventClass)
{
    /** Construct an event handler. */
    this(Handler)(Handler handler)
        if (is(typeof(isEventHandler!(Handler, EventClass))) && isEventHandler!(Handler, EventClass))
    {
        _callback = Callback(handler);
    }

    /** Assign an event handler. */
    void opAssign(Handler)(Handler handler)  // note: typeof check due to overload matching issue
        if (is(typeof(isEventHandler!(Handler, EventClass))) && isEventHandler!(Handler, EventClass))
    {
        _callback = Callback(handler);
    }

    /** Ditto. */
    void opAssign(typeof(this) rhs)
    {
        _callback = rhs._callback;
    }

    /** Clear the event handler. */
    void opAssign(typeof(null))
    {
        _callback.clear();
    }

    /** Ditto. */
    void clear()
    {
        _callback.clear();
    }

    /**
        Call the event handler with the $(D event).
        If no event handler was set, the function
        returns early.
    */
    package void call(scope EventClass event)
    {
        if (_callback.deleg)
            _callback.deleg(event);
        else
        if (_callback.func)
            _callback.func(event);
    }

private:

    static struct Callback
    {
        this(T)(T handler)
        {
            static if (is(T == class))
            {
                static if (isDelegate!(typeof(&handler.opCall)))
                    this.deleg = cast(Deleg)&handler.opCall;
                else
                    this.func = cast(Func)&handler.opCall;
            }
            else
            static if (isPointer!T && is(pointerTarget!T == struct))
            {
                static if (isDelegate!(typeof(&pointerTarget!T.init.opCall)))
                    this.deleg = cast(Deleg)&handler.opCall;
                else
                    this.func = cast(Func)&handler.opCall;
            }
            else
            static if (isDelegate!T)
            {
                this.deleg = cast(Deleg)handler;
            }
            else
            static if (isFunctionPointer!T)
            {
                this.func = cast(Func)handler;
            }
            else
            static assert(0);
        }

        alias Func  = void function(scope EventClass);
        alias Deleg = void delegate(scope EventClass);

        Deleg deleg;
        Func func;

        void clear()
        {
            if (deleg !is null)
                deleg = null;

            if (func !is null)
                func  = null;
        }
    }

private:
    Callback _callback;
}

///
unittest
{
    import core.exception;
    import std.exception;

    static class MyEvent
    {
        this(int x, int y)
        {
            this.x = x;
            this.y = y;
        }

        int x;
        int y;
    }

    EventHandler!MyEvent handler;

    bool hasDgRun;
    auto event = scoped!MyEvent(1, 2);

    static assert(!is(typeof( handler = 1 )));
    static assert(!is(typeof( handler = () { } )));
    static assert(!is(typeof( handler = (MyEvent event) { } )));
    static assert(is(typeof( handler = (scope MyEvent event) { } )));

    struct SF1 { void opCall() { } }
    struct SF2 { void opCall(MyEvent event) { } }
    struct SK1 { void opCall(scope MyEvent event) { hasDgRun = true; assert(event.x == 1 && event.y == 2); } }
    struct SK2 { static void opCall(scope MyEvent event) { assert(event.x == 1 && event.y == 2); } }

    SF1 sf1;
    SF2 sf2;
    SK1 sk1;
    SK2 sk2;

    static assert(!is(typeof( handler = sf1 )));
    static assert(!is(typeof( handler = sf2 )));
    static assert(!is(typeof( handler = sk1 )));
    static assert(!is(typeof( handler = sk2 )));

    static assert(!is(typeof( handler = &sf1 )));
    static assert(!is(typeof( handler = &sf2 )));
    static assert(is(typeof( handler = &sk1 )));
    static assert(is(typeof( handler = &sk2 )));

    class CF1 { void opCall() { } }
    class CF2 { void opCall(MyEvent event) { } }
    class CK1 { void opCall(scope MyEvent event) { hasDgRun = true; assert(event.x == 1 && event.y == 2); } }
    class CK2 { static void opCall(scope MyEvent event) { assert(event.x == 1 && event.y == 2); } }

    CF1 cf1;
    CF2 cf2;
    CK1 ck1 = new CK1();
    CK2 ck2 = new CK2();

    static assert(!is(typeof( handler = cf1 )));
    static assert(!is(typeof( handler = cf2 )));
    static assert(is(typeof( handler = ck1 )));
    static assert(is(typeof( handler = ck2 )));

    /* test delegate lambda. */
    handler = (scope MyEvent event) { hasDgRun = true; assert(event.x == 1 && event.y == 2); };
    handler.call(event);
    assert(hasDgRun == true);

    hasDgRun = false;
    handler = null;
    handler.call(event);
    assert(!hasDgRun);

    /* test function lambda. */
    handler = function void(scope MyEvent event) { assert(event.x == 1 && event.y == 2); };
    handler.call(event);
    event.x = 2;
    assertThrown!AssertError(handler.call(event));

    /* test struct opCall. */
    event.x = 1;
    hasDgRun = false;
    handler = &sk1;
    handler.call(event);
    assert(hasDgRun);

    hasDgRun = false;
    handler = &sk2;
    handler.call(event);
    assert(!hasDgRun);

    event.x = 2;
    assertThrown!AssertError(handler.call(event));

    /* test class opCall. */
    event.x = 1;
    hasDgRun = false;
    handler = ck1;
    handler.call(event);
    assert(hasDgRun);

    hasDgRun = false;
    handler = ck2;
    handler.call(event);
    assert(!hasDgRun);

    event.x = 2;
    assertThrown!AssertError(handler.call(event));

    /* test ctor syntax */
    auto newHandler = typeof(handler)(ck2);

    /* test equality asignment */
    auto newHandler2 = newHandler;
}

/**
    A signal holds multiple event handlers to call.

    See the $(D EventHandler) documentation on which types
    of event handlers are allowed to be set.
*/
struct Signal(EventClass)
{
    /** Add a handler to the list of handlers at the end of the list. */
    void connect(T)(T handler)
        if (isEventHandler!(T, EventClass))
    {
        auto call = HandlerType(handler);
        assert(find(_handlers[], call).empty, "Handler is already registered!");
        _handlers.stableInsertAfter(_handlers[], call);
        ++handlersCount;
    }

    /** Convenience append-assign operator, equivalent to calling $(D connect). */
    void opOpAssign(string op : "~", T)(T handler)
        if (isEventHandler!(T, EventClass))
    {
        this.connect(handler);
    }

    /** Add a handler to the list of handlers at the beginning of the list. */
    void connectFirst(T)(T handler)
        if (isEventHandler!(T, EventClass))
    {
        auto call = HandlerType(handler);
        assert(find(_handlers[], call).empty, "Handler is already registered!");
        _handlers.stableInsertFront(call);
        ++handlersCount;
    }

    /**
        Add a handler to be called before another handler.
        Params:
            beforeThis = The new attached handler will be called after this handler
            handler = The handler to be attached
    */
    void connectBefore(T, U)(T beforeThis, U handler)
        if (isEventHandler!(T, EventClass) && isEventHandler!(U, EventClass))
    {
        auto before = HandlerType(beforeThis);
        auto call = HandlerType(handler);

        auto location = find(_handlers[], before);
        if (location.empty)
             throw new Exception("Handler 'beforeThis' is not registered!");

        assert(find(_handlers[], call).empty, "Handler is already registered!");

        // not exactly fast
        size_t length = walkLength(_handlers[]);
        size_t pos = walkLength(location);
        size_t new_location = length - pos;
        location = _handlers[];

        if (new_location == 0)
            _handlers.stableInsertFront(call);
        else
            _handlers.stableInsertAfter(take(location, new_location), call);

        ++handlersCount;
    }

    /**
        Add a handler to be called after another handler.
        Params:
            afterThis = The new attached handler will be called after this handler
            handler = The handler to be attached
    */
    void connectAfter(T, U)(T afterThis, U handler)
       if (isEventHandler!(T, EventClass) && isEventHandler!(U, EventClass))
    {
        auto after = HandlerType(afterThis);
        auto call = HandlerType(handler);
        auto location = find(_handlers[], after);

        if (location.empty)  // afterThis not found
        {
            // always connect before manager
            connectFirst(handler);
        }
        else
        {
            assert(find(_handlers[], call).empty, "Handler is already registered!");
            _handlers.stableInsertAfter(location.take(1), call);
            ++handlersCount;
        }
    }

    /**
        Replace a handler with another handler.
        Params:
            oldHandler = The old handler which will be removed.
            newHandler = The handler to be attached at the same position.
    */
    void replace(T, U)(T oldHandler, U newHandler)
        if (isEventHandler!(T, EventClass) && isEventHandler!(U, EventClass))
    {
        this.connectAfter(newHandler, oldHandler);
        this.disconnect(oldHandler);
    }

    /** Remove a handler from the list of handlers. */
    void disconnect(T)(T handler)
        if (isEventHandler!(T, EventClass))
    {
        auto call = HandlerType(handler);
        auto pos = find(_handlers[], call);
        if (pos.empty)
        {
            throw new Exception("Handler is not connected");
        }
        _handlers.stableLinearRemove(pos.take(1));
        --handlersCount;
    }

    /** Check whether a handler is in this list. */
    bool isConnected(T)(T handler)
        if (isEventHandler!(T, EventClass))
    {
        auto call = HandlerType(handler);
        return !find(_handlers[], call).empty;
    }

    /** Remove all handlers from the list. */
    void clear()
    {
        _handlers.clear();
        handlersCount = 0;
    }

    /** Get the number of handlers in the list. */
    size_t length()
    {
        return handlersCount;
    }

    /** Get a forward range of all the handlers. */
    package @property auto handlers()
    {
        return _handlers[];
    }

    /** Emit a signal until the event is handled. */
    package void emit(scope EventClass event)
    {
        foreach (handler; _handlers)
        {
            handler.call(event);
            if (event.handled)
                break;
        }
    }

private:
    alias HandlerType = EventHandler!EventClass;

private:
    SList!HandlerType _handlers;
    size_t handlersCount;
}

private alias stcType = ParameterStorageClass;
private alias storages = ParameterStorageClassTuple;

/** Check whether $(D T) is a handler function which can be called with the $(D Types). */
template isEventHandler(T, Types...)
    if (isSomeFunction!T)
{
    enum bool isEventHandler = is(typeof(T.init(Types.init))) &&
                          storages!(T)[0] == stcType.scope_ &&
                          is(ReturnType!T == void);
}

/** Check whether $(D T) is a pointer to a struct with an $(D opCall) function which can be called with the $(D Types). */
template isEventHandler(T, Types...)
    if (isPointer!T && is(pointerTarget!T == struct))
{
    enum bool isEventHandler = is(typeof(pointerTarget!T.init.opCall(Types.init))) &&
                          storages!(pointerTarget!T.init.opCall)[0] == stcType.scope_ &&
                          is(ReturnType!T == void);
}

/** Check whether $(D T) is a class with an $(D opCall) function which can be called with the $(D Types). */
template isEventHandler(T, Types...)
    if (is(T == class))
{
    // we need a static if due to eager logical 'and' operator semantics
    static if (is(typeof(T.init.opCall(Types.init))))
    {
        enum bool isEventHandler = is(typeof(T.init.opCall(Types.init)) == void) &&
                              storages!(T.init.opCall)[0] == stcType.scope_;
    }
    else
    {
        enum bool isEventHandler = false;
    }
}

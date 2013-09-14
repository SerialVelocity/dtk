/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dtk.widgets.menu;

import std.exception;
import std.range;

import dtk.app;
import dtk.dispatch;
import dtk.event;
import dtk.interpreter;
import dtk.signals;
import dtk.types;
import dtk.utils;

import dtk.widgets.widget;
import dtk.widgets.window;

class CommonMenu : Widget
{
    ///
    package this(Widget master, TkType tkType, WidgetType widgetType)
    {
        super(master, tkType, widgetType);
        this.setOption("tearoff", 0);  // disable tearoff by default
    }

    /** Create and add a menu to this menu and return it. */
    final Menu addMenu(string menuName)
    {
        auto menu = new Menu(this, menuName);
        tclEvalFmt("%s add cascade -menu %s -label %s", _name, menu._name, menuName._tclEscape);
        return menu;
    }

    /** Create and insert a menu at a specific position and return it. */
    final Menu insertMenu(int index, string menuName)
    {
        auto menu = new Menu(this, menuName);
        tclEvalFmt("%s insert %s cascade -menu %s -label %s", _name, index, menu._name, menuName._tclEscape);
        return menu;
    }

    /** Add an item to this menu and return it. */
    final MenuItem addItem(string menuItemName)
    {
        auto menuItem = new MenuItem(menuItemName);

        tclEvalFmt("%s add command -label %s -command %s", _name, menuItemName,
            getCommand(MenuAction.command, menuItem));

        return menuItem;
    }

    /** Insert an item at a specific position and return it. */
    final MenuItem insertItem(int index, string menuItemName)
    {
        auto menuItem = new MenuItem(menuItemName);

        tclEvalFmt("%s insert %s command -label %s -command %s", _name, index, menuItemName,
            getCommand(MenuAction.command, menuItem));

        return menuItem;
    }

    /** Add a check menu item to this menu. */
    final void addItem(string label, string offValue, string onValue)
    {
        //~ assert(!_name.empty);
        //~ tclEvalFmt("%s add checkbutton -label %s -variable %s -onvalue %s -offvalue %s", _name, menuItem._label._tclEscape, menuItem._toggleVarName, menuItem._onValue._tclEscape, menuItem._offValue._tclEscape);
    }

    /** Insert a check menu item at a specific position. */
    final void insertItem(int index, string label, string offValue, string onValue)
    {
        //~ assert(!_name.empty);
        //~ tclEvalFmt("%s insert %s checkbutton -label %s -variable %s -onvalue %s -offvalue %s", _name, index, menuItem._label._tclEscape, menuItem._toggleVarName, menuItem._onValue._tclEscape, menuItem._offValue._tclEscape);
    }

    private MenuBar getRootMenuBar()
    {
        Widget parent = this;

        do
        {
            if (parent.widgetType == WidgetType.menubar)
                return StaticCast!MenuBar(parent);
            else
                parent = parent.parentWidget;
        } while (parent !is null);

        assert(0);
    }

    private string getCommand(MenuAction menuAction, Widget menuItem)
    {
        auto menuBar = this.getRootMenuBar();

        return format(`"%s %s %s %s"`,
                      _dtkCallbackIdent,
                      EventType.menu,
                      menuAction,
                      menuBar._name,
                      menuItem._name);
    }
}

class MenuBar : CommonMenu
{
    /** Signal emitted when a menu item is selected. */
    public Signal!MenuEvent onMenuEvent;

    ///
    package this(Widget master)
    {
        super(master, TkType.menu, WidgetType.menubar);
    }
}

///
class Menu : CommonMenu
{
    package this(Widget master, string label)
    {
        _label = label;
        super(master, TkType.menu, WidgetType.menu);
    }

    /** Add a dividing line. */
    final void addSeparator()
    {
        tclEvalFmt("%s add separator", _name);
    }

    /** Insert a dividing line at a specific position. */
    final void insertSeparator(int index)
    {
        tclEvalFmt("%s insert %s separator", _name, index);
    }

    /** Get the menu label. */
    @property string label()
    {
        return _label;
    }

private:
    string _label;
}

///
class MenuItem : Widget
{
    ///
    package this(string label)
    {
        _label = label;
        super(CreateFakeWidget.init, WidgetType.menuitem);
    }

    /** Get the menu item label. */
    @property string label()
    {
        return _label;
    }

private:
    string _label;
}

/// Common code for menu bars and menus
/+ abstract class MenuClass : Widget
{
    this(InitLater initLater, WidgetType widgetType)
    {
        super(initLater, widgetType);
    }

    /** A menu must always have a parent, so proper initialization is required. */
    package void initParent(Widget master)
    {
        this.initialize(master, TkType.menu);
        this.setOption("tearoff", 0);  // disable tearoff by default
    }

    /** Add a menu to this menu. */
    final void addMenu(Menu menu)
    {
        assert(!_name.empty);
        menu.initParent(this);
        tclEvalFmt("%s add cascade -menu %s -label %s", _name, menu._name, menu._label._tclEscape);
    }

    /** Insert a menu at a specific position. */
    final void insertMenu(Menu menu, int index)
    {
        assert(!_name.empty);
        menu.initParent(this);
        tclEvalFmt("%s insert %s cascade -menu %s -label %s", _name, index, menu._name, menu._label._tclEscape);
    }

    /** Add an item to this menu. */
    final void addItem(MenuItem menuItem)
    {
        assert(!_name.empty);
        tclEvalFmt("%s add command -label %s -command { %s %s }", _name, menuItem._label, _dtkCallbackIdent, TkEventType.TkMenuItemSelect);
    }

    /** Insert an item at a specific position. */
    final void insertItem(MenuItem menuItem, int index)
    {
        assert(!_name.empty);
        tclEvalFmt("%s insert %s command -label %s -command { %s %s }", _name, index, menuItem._label._tclEscape, _dtkCallbackIdent, TkEventType.TkMenuItemSelect);
    }

    /** Add a check menu item to this menu. */
    final void addItem(CheckMenuItem menuItem)
    {
        assert(!_name.empty);
        tclEvalFmt("%s add checkbutton -label %s -variable %s -onvalue %s -offvalue %s", _name, menuItem._label._tclEscape, menuItem._toggleVarName, menuItem._onValue._tclEscape, menuItem._offValue._tclEscape);
    }

    /** Insert a check menu item at a specific position. */
    final void insertItem(CheckMenuItem menuItem, int index)
    {
        assert(!_name.empty);
        tclEvalFmt("%s insert %s checkbutton -label %s -variable %s -onvalue %s -offvalue %s", _name, index, menuItem._label._tclEscape, menuItem._toggleVarName, menuItem._onValue._tclEscape, menuItem._offValue._tclEscape);
    }

    /** Add a radio menu group to this menu. */
    final void addItem(RadioGroupMenu menuItem)
    {
        assert(!_name.empty);

        foreach (radioMenuItem; menuItem.items)
        {
            tclEvalFmt("%s add radiobutton -label %s -variable %s -value %s",
                _name, radioMenuItem._label._tclEscape, menuItem._varName, radioMenuItem._value);
        }
    }

    /** Insert a radio menu group at a specific position. */
    final void insertItem(RadioGroupMenu menuItem, int index)
    {
        assert(!_name.empty);

        foreach (radioMenuItem; menuItem.items)
        {
            tclEvalFmt("%s insert %s radiobutton -label %s -variable %s -value %s",
                _name, index++, radioMenuItem._label._tclEscape, menuItem._varName, radioMenuItem._value);
        }
    }
}

///
class MenuBar : MenuClass
{
    this()
    {
        super(InitLater.init, WidgetType.menubar);
    }
}

///
class Menu : MenuClass
{
    ///
    this(string label)
    {
        _label = label;
        super(InitLater.init, WidgetType.menu);
    }

    /** Add a dividing line. */
    final void addSeparator()
    {
        tclEvalFmt("%s add separator", _name);
    }

    /** Insert a dividing line at a specific position. */
    final void insertSeparator(int index)
    {
        tclEvalFmt("%s insert %s separator", _name, index);
    }

    /** Get the menu label. */
    @property string label()
    {
        return _label;
    }

private:
    string _label;
}

///
class MenuItem : Widget
{
    ///
    this(string label)
    {
        _label = label;
        super(CreateFakeWidget.init, WidgetType.menuitem);
    }

    /** Get the menu item label. */
    @property string label()
    {
        return _label;
    }

private:
    string _label;
}

///
class CheckMenuItem : Widget
{
    ///
    this(string label, string offValue = "0", string onValue = "1")
    {
        _label = label;
        _offValue = offValue;
        _onValue = onValue;
        super(CreateFakeWidget.init, WidgetType.checkmenu_item);
        _toggleVarName = makeTracedVar(TkEventType.TkCheckMenuItemToggle);
    }

    /** Get the menu item label. */
    @property string label()
    {
        return _label;
    }

    /** Get the current state of the checkbutton. It should equal to either onValue or offValue. */
    @property string value()
    {
        return tclGetVar!string(_toggleVarName);
    }

private:
    string _label;
    string _toggleVarName;
    string _offValue;
    string _onValue;
}

///
class RadioGroupMenu : Widget
{
    // todo: this is not really a Widget, but it needs to have a callback mechanism
    this()
    {
        super(CreateFakeWidget.init, WidgetType.radiogroup_menu);
        _varName = makeTracedVar(TkEventType.TkRadioMenuSelect);
    }

    /**
        Get the currently selected radio menu value.
        It should equal to the $(D value) property of one of
        the radio menus that are part of this radio group.
    */
    @property string value()
    {
        return tclGetVar!string(_varName);
    }

    /**
        Set the currently selected radio menu value.
        It should equal to the $(D value) property of one of
        the radio menus that are part of this radio group.
    */
    @property void value(string newValue)
    {
        tclSetVar(_varName, newValue);
    }

    private void add(RadioMenuItem item)
    {
        if (items.empty)
            this.value = item.value;

        items ~= item;
    }

private:
    RadioMenuItem[] items;
    string _varName;
}

///
class RadioMenuItem : Widget
{
    ///
    this(RadioGroupMenu radioGroup, string label, string value)
    {
        enforce(radioGroup !is null, "radioGroup argument must not be null.");
        _radioGroup = radioGroup;
        _label = label;
        _value = value;
        radioGroup.add(this);
        super(CreateFakeWidget.init, WidgetType.radiomenu_item);
    }

    /** Return the value that's emitted when this radio menu is selected. */
    @property string value()
    {
        return this.getOption!string("value");
    }

    /** Set the value that's emitted when this radio menu is selected. */
    @property void value(string newValue)
    {
        auto oldValue = this.value;

        this.setOption("value", newValue);

        if (_radioGroup.value == oldValue)
            _radioGroup.value = newValue;
    }

    /** Select this radio menu. */
    void select()
    {
        _radioGroup.value = this.value;
    }

private:
    RadioGroupMenu _radioGroup;
    string _label;
    string _value;
}
 +/

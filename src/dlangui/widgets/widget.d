// Written in the D programming language.

/**
DLANGUI library.

This module contains declaration of Widget class - base class for all widgets.



Synopsis:

----
import dlangui.widgets.widget;

----

Copyright: Vadim Lopatin, 2014
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   $(WEB coolreader.org, Vadim Lopatin)
*/
module dlangui.widgets.widget;

public import dlangui.core.types;
public import dlangui.core.events;
public import dlangui.widgets.styles;
public import dlangui.graphics.drawbuf;
//public import dlangui.graphics.images;
public import dlangui.graphics.resources;
public import dlangui.graphics.fonts;
public import dlangui.core.i18n;

//public import std.signals;
public import dlangui.core.signals;

import dlangui.platforms.common.platform;

import std.algorithm;


/// Visibility (see Android View Visibility)
enum Visibility : ubyte {
    /// Visible on screen (default)
    Visible,
    /// Not visible, but occupies a space in layout
    Invisible,
    /// Completely hidden, as not has been added
    Gone
}

enum Orientation : ubyte {
    Vertical,
    Horizontal
}

/// interface - slot for onClick
interface OnClickHandler {
    bool onClick(Widget source);
}

/// interface - slot for onCheckChanged
interface OnCheckHandler {
    bool onCheckChanged(Widget source, bool checked);
}

/// interface - slot for onFocusChanged
interface OnFocusHandler {
    bool onFocusChanged(Widget source, bool focused);
}

/// focus movement options
enum FocusMovement {
    /// no focus movement
    None,
    /// next focusable (Tab)
    Next,
    /// previous focusable (Shift+Tab)
    Previous,
    /// move to nearest above
    Up,
    /// move to nearest below
    Down,
    /// move to nearest at left
    Left,
    /// move to nearest at right
    Right,
}

class Widget {
    /// widget id
    protected string _id;
    /// current widget position, set by layout()
    protected Rect _pos;
    /// widget visibility: either Visible, Invisible, Gone
    protected Visibility _visibility = Visibility.Visible; // visible by default
    /// style id to lookup style in theme
	protected string _styleId;
    /// own copy of style - to override some of style properties, null of no properties overriden
	protected Style _ownStyle;

    /// widget state (set of flags from State enum)
    protected uint _state;

    /// width measured by measure()
    protected int _measuredWidth;
    /// height measured by measure()
    protected int _measuredHeight;
    /// true to force layout
    protected bool _needLayout = true;
    /// true to force redraw
    protected bool _needDraw = true;
    /// parent widget
    protected Widget _parent;
    /// window (to be used for top level widgets only!)
    protected Window _window;

    /// does widget need to track mouse Hover
    protected bool _trackHover;

    /// mouse movement processing flag (when true, widget will change Hover state while mouse is moving)
    @property bool trackHover() const { return _trackHover; }
    /// set new trackHover flag value (when true, widget will change Hover state while mouse is moving)
    @property Widget trackHover(bool v) { _trackHover = v; return this; }

    debug {
	    private static int _instanceCount = 0;
        private static bool _appShuttingDown = false;
    }
	/// create widget, with optional id
    this(string ID = null) {
		_id = ID;
        _state = State.Enabled;
        debug {
            _instanceCount++;
        }
		//Log.d("Created widget, count = ", ++_instanceCount);
    }
	~this() {
        debug {
            //Log.v("destroying widget ", _id);
            if (_appShuttingDown)
                Log.e("Destroying widget ", _id, " after app shutdown: probably, resource leak");
            _instanceCount--;
        }
		if (_ownStyle !is null)
			destroy(_ownStyle);
		_ownStyle = null;
		//Log.d("Destroyed widget, count = ", --_instanceCount);
	}
    debug {
        /// for debug purposes - number of created widget objects, not yet destroyed
        static @property int instanceCount() { return _instanceCount; }
        /// for debug purposes - sets shutdown flag to log widgets not destroyed in time.
        static void shuttingDown() {
            _appShuttingDown = true;
        }
    }

    /// accessor to style - by lookup in theme by styleId (if style id is not set, theme base style will be used).
	protected @property const (Style) style() const {
		if (_ownStyle !is null)
			return _ownStyle;
		return currentTheme.get(_styleId);
	}
    /// accessor to style - by lookup in theme by styleId (if style id is not set, theme base style will be used).
	protected @property const (Style) style(uint stateFlags) const {
        const (Style) normalStyle = style();
        if (stateFlags == State.Normal) // state is normal
            return normalStyle;
        const (Style) stateStyle = normalStyle.forState(stateFlags);
        if (stateStyle !is normalStyle)
            return stateStyle; // found style for state in current style
        //// lookup state style in parent (one level max)
        //const (Style) parentStyle = normalStyle.parentStyle;
        //if (parentStyle is normalStyle)
        //    return normalStyle; // no parent
        //const (Style) parentStateStyle = parentStyle.forState(stateFlags);
        //if (parentStateStyle !is parentStyle)
        //    return parentStateStyle; // found style for state in parent
		return normalStyle; // fallback to current style
	}
    /// returns style for current widget state
    protected @property const(Style) stateStyle() const {
        return style(state);
    }

    /// enforces widget's own style - allows override some of style properties
	protected @property Style ownStyle() {
		if (_ownStyle is null)
			_ownStyle = currentTheme.modifyStyle(_styleId);
		return _ownStyle;
	}

    /// returns widget id, null if not set
	@property string id() const { return _id; }
    /// set widget id
    @property Widget id(string id) { _id = id; return this; }
    /// compare widget id with specified value, returs true if matches
    bool compareId(string id) const { return (_id !is null) && id.equal(_id); }

    /// widget state (set of flags from State enum)
    @property uint state() const {
        if ((_state & State.Parent) != 0 && _parent !is null)
            return _parent.state;
        return _state | State.WindowFocused; // TODO:
    }
    /// override to handle focus changes
    protected void handleFocusChange(bool focused) {
        invalidate();
		onFocusChangeListener(this, checked);
    }
    /// override to handle check changes
    protected void handleCheckChange(bool checked) {
        invalidate();
		onCheckChangeListener(this, checked);
    }
    /// set new widget state (set of flags from State enum)
    @property Widget state(uint newState) {
        if (newState != _state) {
            uint oldState = _state;
            _state = newState;
            // need to redraw
            invalidate();
            // notify focus changes
            if ((oldState & State.Focused) && !(newState & State.Focused))
                handleFocusChange(false);
            else if (!(oldState & State.Focused) && (newState & State.Focused))
                handleFocusChange(true);
            // notify checked changes
            if ((oldState & State.Checked) && !(newState & State.Checked))
                handleCheckChange(false);
            else if (!(oldState & State.Checked) && (newState & State.Checked))
                handleCheckChange(true);
        }
        return this;
    }
    /// add state flags (set of flags from State enum)
    @property Widget setState(uint stateFlagsToSet) {
        return state(state | stateFlagsToSet);
    }
    /// remove state flags (set of flags from State enum)
    @property Widget resetState(uint stateFlagsToUnset) {
        return state(state & ~stateFlagsToUnset);
    }



    //======================================================
    // Style related properties

    /// returns widget style id, null if not set
	@property string styleId() const { return _styleId; }
    /// set widget style id
    @property Widget styleId(string id) { _styleId = id; return this; }
    /// get margins (between widget bounds and its background)
    @property Rect margins() const { return style.margins; }
    /// set margins for widget - override one from style
    @property Widget margins(Rect rc) { 
        ownStyle.margins = rc; 
        requestLayout();
        return this; 
    }
    /// get padding (between background bounds and content of widget)
    @property Rect padding() const { 
		// get max padding from style padding and background drawable padding
		Rect p = style.padding; 
		DrawableRef d = style.backgroundDrawable;
		if (!d.isNull) {
			Rect dp = style.backgroundDrawable.padding;
			if (p.left < dp.left)
				p.left = dp.left;
			if (p.right < dp.right)
				p.right = dp.right;
			if (p.top < dp.top)
				p.top = dp.top;
			if (p.bottom < dp.bottom)
				p.bottom = dp.bottom;
		}
		return p;
	}
    /// set padding for widget - override one from style
    @property Widget padding(Rect rc) { 
        ownStyle.padding = rc; 
        requestLayout();
        return this; 
    }
    /// returns background color
    @property uint backgroundColor() const { return stateStyle.backgroundColor; }
    /// set background color for widget - override one from style
    @property Widget backgroundColor(uint color) { 
        ownStyle.backgroundColor = color; 
        invalidate();
        return this; 
    }
    /// get text color (ARGB 32 bit value)
    @property uint textColor() const { return stateStyle.textColor; }
    /// set text color (ARGB 32 bit value)
    @property Widget textColor(uint value) { 
        ownStyle.textColor = value; 
        invalidate();
        return this; 
    }
    /// returns font face
    @property string fontFace() const { return stateStyle.fontFace; }
    /// set font face for widget - override one from style
	@property Widget fontFace(string face) { 
        ownStyle.fontFace = face; 
        requestLayout();
        return this; 
    }
    /// returns font style (italic/normal)
    @property bool fontItalic() const { return stateStyle.fontItalic; }
    /// set font style (italic/normal) for widget - override one from style
	@property Widget fontItalic(bool italic) { 
        ownStyle.fontStyle = italic ? FONT_STYLE_ITALIC : FONT_STYLE_NORMAL; 
        requestLayout();
        return this; 
    }
    /// returns font weight
    @property ushort fontWeight() const { return stateStyle.fontWeight; }
    /// set font weight for widget - override one from style
	@property Widget fontWeight(ushort weight) { 
        ownStyle.fontWeight = weight; 
        requestLayout();
        return this; 
    }
    /// returns font size in pixels
    @property ushort fontSize() const { return stateStyle.fontSize; }
    /// set font size for widget - override one from style
	@property Widget fontSize(ushort size) { 
        ownStyle.fontSize = size; 
        requestLayout();
        return this; 
    }
    /// returns font family
    @property FontFamily fontFamily() const { return stateStyle.fontFamily; }
    /// set font family for widget - override one from style
    @property Widget fontFamily(FontFamily family) { 
        ownStyle.fontFamily = family; 
        requestLayout();
        return this; 
    }
    /// returns alignment (combined vertical and horizontal)
    @property ubyte alignment() const { return style.alignment; }
    /// sets alignment (combined vertical and horizontal)
    @property Widget alignment(ubyte value) { 
        ownStyle.alignment = value; 
        requestLayout();
        return this; 
    }
    /// returns horizontal alignment
    @property Align valign() { return cast(Align)(alignment & Align.VCenter); }
    /// returns vertical alignment
    @property Align halign() { return cast(Align)(alignment & Align.HCenter); }
    /// returns font set for widget using style or set manually
    @property FontRef font() const { return stateStyle.font; }

    /// returns widget content text (override to support this)
    @property dstring text() { return ""; }
    /// sets widget content text (override to support this)
    @property Widget text(dstring s) { return this; }
    /// sets widget content text (override to support this)
    @property Widget text(ref UIString s) { return this; }

    //==================================================================
    // Layout and drawing related methods

    /// returns true if layout is required for widget and its children
    @property bool needLayout() { return _needLayout; }
    /// returns true if redraw is required for widget and its children
    @property bool needDraw() { return _needDraw; }
    /// returns true is widget is being animated - need to call animate() and redraw
    @property bool animating() { return false; }
    /// animates window; interval is time left from previous draw, in hnsecs (1/10000 of second)
    void animate(long interval) {
    }
    /// returns measured width (calculated during measure() call)
    @property measuredWidth() { return _measuredWidth; }
    /// returns measured height (calculated during measure() call)
    @property measuredHeight() { return _measuredHeight; }
    /// returns current width of widget in pixels
    @property int width() { return _pos.width; }
    /// returns current height of widget in pixels
    @property int height() { return _pos.height; }
    /// returns widget rectangle top position
    @property int top() { return _pos.top; }
    /// returns widget rectangle left position
    @property int left() { return _pos.left; }
    /// returns widget rectangle
    @property Rect pos() { return _pos; }
    /// returns min width constraint
    @property int minWidth() { return style.minWidth; }
    /// returns max width constraint (SIZE_UNSPECIFIED if no constraint set)
    @property int maxWidth() { return style.maxWidth; }
    /// returns min height constraint
    @property int minHeight() { return style.minHeight; }
    /// returns max height constraint (SIZE_UNSPECIFIED if no constraint set)
    @property int maxHeight() { return style.maxHeight; }

    /// set max width constraint (SIZE_UNSPECIFIED for no constraint)
    @property Widget maxWidth(int value) { ownStyle.maxWidth = value; return this; }
    /// set max width constraint (0 for no constraint)
    @property Widget minWidth(int value) { ownStyle.minWidth = value; return this; }
    /// set max height constraint (SIZE_UNSPECIFIED for no constraint)
    @property Widget maxHeight(int value) { ownStyle.maxHeight = value; return this; }
    /// set max height constraint (0 for no constraint)
    @property Widget minHeight(int value) { ownStyle.minHeight = value; return this; }

    /// returns layout width options (WRAP_CONTENT, FILL_PARENT, or some constant value)
    @property int layoutWidth() { return style.layoutWidth; }
    /// returns layout height options (WRAP_CONTENT, FILL_PARENT, or some constant value)
    @property int layoutHeight() { return style.layoutHeight; }
    /// returns layout weight (while resizing to fill parent, widget will be resized proportionally to this value)
    @property int layoutWeight() { return style.layoutWeight; }

    /// sets layout width options (WRAP_CONTENT, FILL_PARENT, or some constant value)
    @property Widget layoutWidth(int value) { ownStyle.layoutWidth = value; return this; }
    /// sets layout height options (WRAP_CONTENT, FILL_PARENT, or some constant value)
    @property Widget layoutHeight(int value) { ownStyle.layoutHeight = value; return this; }
    /// sets layout weight (while resizing to fill parent, widget will be resized proportionally to this value)
    @property Widget layoutWeight(int value) { ownStyle.layoutWeight = value; return this; }

    /// returns widget visibility (Visible, Invisible, Gone)
    @property Visibility visibility() { return _visibility; }
    /// sets widget visibility (Visible, Invisible, Gone)
    @property Widget visibility(Visibility visible) {
        if (_visibility != visible) {
            if ((_visibility == Visibility.Gone) || (visible == Visibility.Gone))
                requestLayout();
            else
                invalidate();
            _visibility = visible;
        }
        return this;
    }

    /// returns true if point is inside of this widget
    bool isPointInside(int x, int y) {
        return _pos.isPointInside(x, y);
    }

	/// return true if state has State.Enabled flag set
    @property bool enabled() { return (state & State.Enabled) != 0; }
	/// change enabled state
    @property Widget enabled(bool flg) { flg ? setState(State.Enabled) : resetState(State.Enabled); return this; }

    protected bool _clickable;
	/// when true, user can click this control, and get onClick listeners called
    @property bool clickable() { return _clickable; }
    @property Widget clickable(bool flg) { _clickable = flg; return this; }
    @property bool canClick() { return _clickable && enabled && visible; }

    protected bool _checkable;
	/// when true, control supports Checked state
    @property bool checkable() { return _checkable; }
    @property Widget checkable(bool flg) { _checkable = flg; return this; }
    @property bool canCheck() { return _checkable && enabled && visible; }


    protected bool _checked;
    /// get checked state
    @property bool checked() { return (state & State.Checked) != 0; }
    /// set checked state
    @property Widget checked(bool flg) { 
        if (flg != checked) {
            if (flg) 
                setState(State.Checked); 
            else 
                resetState(State.Checked); 
            invalidate(); 
        }
        return this; 
    }

    protected bool _focusable;
    /// whether widget can be focused
    @property bool focusable() { return _focusable; }
    @property Widget focusable(bool flg) { _focusable = flg; return this; }

    @property bool focused() {
        return (window !is null && window.focusedWidget is this && (state & State.Focused));
    }

    protected bool _focusGroup;
    /*****************************************
     * When focus group is set for some parent widget, focus from one of containing widgets can be moved using keyboard only to one of other widgets containing in it and cannot bypass bounds of focusGroup.
     * 
     * If focused widget doesn't have any parent with focusGroup == true, focus may be moved to any focusable within window.
     *
     */
    @property bool focusGroup() { return _focusGroup; }
    /// set focus group flag for container widget
    @property Widget focusGroup(bool flg) { _focusGroup = flg; return this; }

    /// find nearest parent of this widget with focusGroup flag, returns topmost parent if no focusGroup flag set to any of parents.
    Widget focusGroupWidget() {
        Widget p = this;
        while (p) {
            if (!p.parent || p.focusGroup)
                break;
            p = p.parent;
        }
        return p;
    }

    private static class TabOrderInfo {
        Widget widget;
        uint tabOrder;
        uint childOrder;
        Rect rect;
        this(Widget widget, Rect rect) {
            this.widget = widget;
            this.tabOrder = widget.thisOrParentTabOrder();
            this.rect = widget.pos;
        }
        static immutable int NEAR_THRESHOLD = 10;
        bool nearX(TabOrderInfo v) {
            return v.rect.left >= rect.left - NEAR_THRESHOLD  && v.rect.left <= rect.left + NEAR_THRESHOLD;
        }
        bool nearY(TabOrderInfo v) {
            return v.rect.top >= rect.top - NEAR_THRESHOLD  && v.rect.top <= rect.top + NEAR_THRESHOLD;
        }
        override int opCmp(Object obj) {
            TabOrderInfo v = cast(TabOrderInfo)obj;
            if (tabOrder != 0 && v.tabOrder !=0) {
                if (tabOrder < v.tabOrder)
                    return -1;
                if (tabOrder > v.tabOrder)
                    return 1;
            }
            // place items with tabOrder 0 after items with tabOrder non-0
            if (tabOrder != 0)
                return -1;
            if (v.tabOrder != 0)
                return 1;
            if (childOrder < v.childOrder)
                return -1;
            if (childOrder > v.childOrder)
                return 1;
            return 0;
        }
        /// less predicat for Left/Right sorting
        static bool lessHorizontal(TabOrderInfo obj1, TabOrderInfo obj2) {
            if (obj1.nearY(obj2)) {
                return obj1.rect.left < obj2.rect.left;
            }
            return obj1.rect.top < obj2.rect.top;
        }
        /// less predicat for Up/Down sorting
        static bool lessVertical(TabOrderInfo obj1, TabOrderInfo obj2) {
            if (obj1.nearX(obj2)) {
                return obj1.rect.top < obj2.rect.top;
            }
            return obj1.rect.left < obj2.rect.left;
        }
    }

    private void findFocusableChildren(ref TabOrderInfo[] results, Rect clipRect) {
        if (visibility != Visibility.Visible)
            return;
        Rect rc = _pos;
        applyMargins(rc);
        applyPadding(rc);
        if (!rc.intersects(clipRect))
            return; // out of clip rectangle
        if (focusable) {
            TabOrderInfo item = new TabOrderInfo(this, rc);
            results ~= item;
            return;
        }
        rc.intersect(clipRect);
        for (int i = 0; i < childCount(); i++) {
            child(i).findFocusableChildren(results, rc);
        }
    }

    /// find all focusables belonging to the same focusGroup as this widget (does not include current widget).
    /// usually to be called for focused widget to get possible alternatives to navigate to
    private TabOrderInfo[] findFocusables() {
        TabOrderInfo[] result;
        Widget group = focusGroupWidget();
        group.findFocusableChildren(result, group.pos);
        for (ushort i = 0; i < result.length; i++)
            result[i].childOrder = i + 1;
        sort(result);
        return result;
    }

    protected ushort _tabOrder;
    /// tab order - hint for focus movement using Tab/Shift+Tab
    @property ushort tabOrder() { return _tabOrder; }
    @property Widget tabOrder(ushort tabOrder) { _tabOrder = tabOrder; return this; }
    private int thisOrParentTabOrder() {
        if (_tabOrder)
            return _tabOrder;
        if (!parent)
            return 0;
        return parent.thisOrParentTabOrder;
    }

    /// call on focused widget, to find best 
    private Widget findNextFocusWidget(FocusMovement direction) {
        if (direction == FocusMovement.None)
            return this;
        TabOrderInfo[] focusables = findFocusables();
        if (!focusables.length)
            return null;
        int myIndex = -1;
        for (int i = 0; i < focusables.length; i++) {
            if (focusables[i].widget is this) {
                myIndex = i;
                break;
            }
        }
        if (myIndex == -1)
            return null; // not found myself
        if (focusables.length == 1)
            return focusables[0].widget; // single option - use it
        if (direction == FocusMovement.Next) {
            // move forward
            int index = myIndex + 1;
            if (index >= focusables.length)
                index = 0;
            return focusables[index].widget;
        } else if (direction == FocusMovement.Previous) {
            // move back
            int index = myIndex - 1;
            if (index < 0)
                index = cast(int)focusables.length - 1;
            return focusables[index].widget;
        } else {
            // Left, Right, Up, Down
            if (direction == FocusMovement.Left || direction == FocusMovement.Right) {
                sort!(TabOrderInfo.lessHorizontal)(focusables);
            } else {
                sort!(TabOrderInfo.lessVertical)(focusables);
            }
            myIndex = 0;
            for (int i = 0; i < focusables.length; i++) {
                if (focusables[i].widget is this) {
                    myIndex = i;
                    break;
                }
            }
            int index = myIndex;
            if (direction == FocusMovement.Left || direction == FocusMovement.Up) {
                index--;
                if (index < 0)
                    index = cast(int)focusables.length - 1;
            } else {
                index++;
                if (index >= focusables.length)
                    index = 0;
            }
            return focusables[index].widget;
        }
    }

    bool handleMoveFocusUsingKeys(KeyEvent event) {
        if (!focused || !visible)
            return false;
        if (!visible)
            return false;
        if (event.action != KeyAction.KeyDown)
            return false;
        FocusMovement direction = FocusMovement.None;
        uint flags = event.flags & (KeyFlag.Shift | KeyFlag.Control | KeyFlag.Alt);
        switch (event.keyCode) {
            case KeyCode.LEFT:
                if (flags == 0)
                    direction = FocusMovement.Left;
                break;
            case KeyCode.RIGHT:
                if (flags == 0)
                    direction = FocusMovement.Right;
                break;
            case KeyCode.UP:
                if (flags == 0)
                    direction = FocusMovement.Up;
                break;
            case KeyCode.DOWN:
                if (flags == 0)
                    direction = FocusMovement.Down;
                break;
            case KeyCode.TAB:
                if (flags == 0)
                    direction = FocusMovement.Next;
                else if (flags == KeyFlag.Shift)
                    direction = FocusMovement.Previous;
                break;
            default:
                break;
        }
        if (direction == FocusMovement.None)
            return false;
        Widget nextWidget = findNextFocusWidget(direction);
        if (!nextWidget)
            return false;
        nextWidget.setFocus();
        return true;
    }

    /// returns true if this widget and all its parents are visible
    @property bool visible() {
        if (visibility != Visibility.Visible)
            return false;
        if (parent is null)
            return true;
        return parent.visible;
    }

    /// returns true if widget is focusable and visible
    @property bool canFocus() {
        return focusable && visible;
    }

    /// sets focus to this widget or suitable focusable child, returns previously focused widget
    Widget setFocus() {
        if (window is null)
            return null;
        if (!visible)
            return window.focusedWidget;
        invalidate();
        if (!canFocus) {
            Widget w = findFocusableChild(true);
            if (!w)
                w = findFocusableChild(false);
            if (w)
                return window.setFocus(w);
            // try to find focusable child
            return window.focusedWidget;
        }
        return window.setFocus(this);
    }
    /// searches children for first focusable item, returns null if not found
    Widget findFocusableChild(bool defaultOnly) {
        for(int i = 0; i < childCount; i++) {
            Widget w = child(i);
            if (w.canFocus && (!defaultOnly || (w.state & State.Default) != 0))
                return w;
            w = w.findFocusableChild(defaultOnly);
            if (w !is null)
                return w;
        }
        if (canFocus)
            return this;
        return null;
    }

    // =======================================================
    // Events

	protected ActionMap _acceleratorMap;
	@property ref ActionMap acceleratorMap() { return _acceleratorMap; }

	/// override to handle specific actions
	protected bool handleAction(Action a) {
		if (parent) // by default, pass to parent widget
			return parent.handleAction(a);
		return false;
	}


    // called to process click and notify listeners
    protected bool handleClick() {
        bool res = onClickListener(this);
        return res;
    }

    /// map key to action
    protected Action findKeyAction(uint keyCode, uint flags) {
        Action action = _acceleratorMap.findByKey(keyCode, flags);
        return action;
    }

    /// process key event, return true if event is processed.
    bool onKeyEvent(KeyEvent event) {
		if (event.action == KeyAction.KeyDown) {
			Action action = findKeyAction(event.keyCode, event.flags & (KeyFlag.Shift | KeyFlag.Alt | KeyFlag.Control));
			if (action !is null) {
				return handleAction(action);
			}
		}
        // handle focus navigation using keys
        if (focused && handleMoveFocusUsingKeys(event))
            return true;
		if (canClick) {
            // support onClick event initiated by Space or Return keys
            if (event.action == KeyAction.KeyDown) {
                if (event.keyCode == KeyCode.SPACE || event.keyCode == KeyCode.RETURN) {
                    setState(State.Pressed);
                    return true;
                }
            }
            if (event.action == KeyAction.KeyUp) {
                if (event.keyCode == KeyCode.SPACE || event.keyCode == KeyCode.RETURN) {
                    resetState(State.Pressed);
                    handleClick();
                    return true;
                }
            }
        }
        return false;
    }

    /// process mouse event; return true if event is processed by widget.
    bool onMouseEvent(MouseEvent event) {
        //Log.d("onMouseEvent ", id, " ", event.action, "  (", event.x, ",", event.y, ")");
		// support onClick
		if (canClick) {
	        if (event.action == MouseAction.ButtonDown && event.button == MouseButton.Left) {
	            setState(State.Pressed);
                if (canFocus)
                    setFocus();
	            return true;
	        }
	        if (event.action == MouseAction.ButtonUp && event.button == MouseButton.Left) {
	            resetState(State.Pressed);
                handleClick();
	            return true;
	        }
	        if (event.action == MouseAction.FocusOut || event.action == MouseAction.Cancel) {
	            resetState(State.Pressed);
	            resetState(State.Hovered);
	            return true;
	        }
	        if (event.action == MouseAction.FocusIn) {
	            setState(State.Pressed);
	            return true;
	        }
		}
        if (canFocus && event.action == MouseAction.ButtonDown && event.button == MouseButton.Left) {
            setFocus();
            return true;
        }
        if (trackHover) {
	        if (event.action == MouseAction.FocusOut || event.action == MouseAction.Cancel) {
                if ((state & State.Hovered)) {
                    Log.d("Hover off ", id);
                    resetState(State.Hovered);
                }
	            return true;
	        }
            if (event.action == MouseAction.Move) {
                if (!(state & State.Hovered)) {
                    Log.d("Hover ", id);
                    setState(State.Hovered);
                }
	            return true;
            }
            if (event.action == MouseAction.Leave) {
                Log.d("Leave ", id);
	            resetState(State.Hovered);
	            return true;
            }
        }
	    return false;
    }

    // =======================================================
    // Signals

	/// on click event listener (bool delegate(Widget))
    Signal!OnClickHandler onClickListener;
	/// checked state change event listener (bool delegate(Widget, bool))
    Signal!OnCheckHandler onCheckChangeListener;
	/// focus state change event listener (bool delegate(Widget, bool))
    Signal!OnFocusHandler onFocusChangeListener;

    /// helper function to add onCheckChangeListener in method chain
    Widget addOnClickListener(bool delegate(Widget) listener) {
        onClickListener.connect(listener);
        return this;
    }

    /// helper function to add onCheckChangeListener in method chain
    Widget addOnCheckChangeListener(bool delegate(Widget, bool) listener) {
        onCheckChangeListener.connect(listener);
        return this;
    }

    /// helper function to add onFocusChangeListener in method chain
    Widget addOnFocusChangeListener(bool delegate(Widget, bool) listener) {
        onFocusChangeListener.connect(listener);
        return this;
    }

    // =======================================================
    // Layout and measurement methods

    /// request relayout of widget and its children
    void requestLayout() {
        _needLayout = true;
    }
    /// request redraw
    void invalidate() {
        _needDraw = true;
    }

    /// helper function for implement measure() when widget's content dimensions are known
    protected void measuredContent(int parentWidth, int parentHeight, int contentWidth, int contentHeight) {
        if (visibility == Visibility.Gone) {
            _measuredWidth = _measuredHeight = 0;
            return;
        }
        Rect m = margins;
        Rect p = padding;
        // summarize margins, padding, and content size
        int dx = m.left + m.right + p.left + p.right + contentWidth;
        int dy = m.top + m.bottom + p.top + p.bottom + contentHeight;
        // apply min/max width and height constraints
        int minw = minWidth;
        int maxw = maxWidth;
        int minh = minHeight;
        int maxh = maxHeight;
        if (dx < minw)
            dx = minw;
        if (dy < minh)
            dy = minh;
        if (maxw != SIZE_UNSPECIFIED && dx > maxw)
            dx = maxw;
        if (maxh != SIZE_UNSPECIFIED && dy > maxh)
            dy = maxh;
        // apply max parent size constraint
        if (parentWidth != SIZE_UNSPECIFIED && dx > parentWidth)
            dx = parentWidth;
        if (parentHeight != SIZE_UNSPECIFIED && dy > parentHeight)
            dy = parentHeight;
        _measuredWidth = dx;
        _measuredHeight = dy;
    }

    /// Measure widget according to desired width and height constraints. (Step 1 of two phase layout).
    void measure(int parentWidth, int parentHeight) { 
        measuredContent(parentWidth, parentHeight, 0, 0);
    }

    /// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
    void layout(Rect rc) {
        if (visibility == Visibility.Gone) {
            return;
        }
        _pos = rc;
        _needLayout = false;
    }
    /// Draw widget at its position to buffer
    void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        Rect rc = _pos;
        applyMargins(rc);
        DrawableRef bg = stateStyle.backgroundDrawable;
		if (!bg.isNull) {
	        bg.drawTo(buf, rc, state);
		}
	    applyPadding(rc);
        _needDraw = false;
    }

    /// Helper function: applies margins to rectangle
    void applyMargins(ref Rect rc) {
        Rect m = margins;
        rc.left += m.left;
        rc.top += m.top;
        rc.bottom -= m.bottom;
        rc.right -= m.right;
    }
    /// Helper function: applies padding to rectangle
    void applyPadding(ref Rect rc) {
        Rect m = padding;
        rc.left += m.left;
        rc.top += m.top;
        rc.bottom -= m.bottom;
        rc.right -= m.right;
    }
    /// Applies alignment for content of size sz - set rectangle rc to aligned value of content inside of initial value of rc.
    void applyAlign(ref Rect rc, Point sz) {
        Align va = valign;
        Align ha = halign;
        if (va == Align.Bottom) {
            rc.top = rc.bottom - sz.y;
        } else if (va == Align.VCenter) {
            int dy = (rc.height - sz.y) / 2;
            rc.top += dy;
            rc.bottom = rc.top + sz.y;
        } else {
            rc.bottom = rc.top + sz.y;
        }
        if (ha == Align.Right) {
            rc.left = rc.right - sz.x;
        } else if (ha == Align.HCenter) {
            int dx = (rc.width - sz.x) / 2;
            rc.left += dx;
            rc.right = rc.left + sz.x;
        } else {
            rc.right = rc.left + sz.x;
        }
    }

    // ===========================================================
    // Widget hierarhy methods

    /// returns number of children of this widget
    @property int childCount() { return 0; }
    /// returns child by index
    Widget child(int index) { return null; }
    /// adds child, returns added item
    Widget addChild(Widget item) { assert(false, "addChild: children not suported for this widget type"); }
    /// removes child, returns removed item
    Widget removeChild(int index) { assert(false, "removeChild: children not suported for this widget type"); }
    /// removes child by ID, returns removed item
    Widget removeChild(string id) { assert(false, "removeChild: children not suported for this widget type"); }
    /// returns index of widget in child list, -1 if passed widget is not a child of this widget
    int childIndex(Widget item) { return -1; }


    /// returns true if item is child of this widget (when deepSearch == true - returns true if item is this widget or one of children inside children tree).
    bool isChild(Widget item, bool deepSearch = true) {
        if (deepSearch) {
            // this widget or some widget inside children tree
            if (item is this)
                return true;
            for (int i = 0; i < childCount; i++) {
                if (child(i).isChild(item))
                    return true;
            }
        } else {
            // only one of children
            for (int i = 0; i < childCount; i++) {
                if (item is child(i))
                    return true;
            }
        }
        return false;
    }

    /// find child by id, returns null if not found
    Widget childById(string id, bool deepSearch = true) { 
        if (deepSearch) {
            // search everywhere inside child tree
            if (compareId(id))
                return this;
            // lookup children
            for (int i = childCount - 1; i >= 0; i--) {
                Widget res = child(i).childById(id);
                if (res !is null)
                    return res;
            }
        } else {
            // search only across children of this widget
            for (int i = childCount - 1; i >= 0; i--)
                if (id.equal(child(i).id))
                    return child(i);
        }
        // not found
        return null; 
    }

    /// returns parent widget, null for top level widget
    @property Widget parent() { return _parent; }
    /// sets parent for widget
    @property Widget parent(Widget parent) { _parent = parent; return this; }
    /// returns window (if widget or its parent is attached to window)
    @property Window window() {
        Widget p = this;
        while (p !is null) {
            if (p._window !is null)
                return p._window;
            p = p.parent;
        }
        return null;
    }
    /// sets window (to be used for top level widget from Window implementation). TODO: hide it from API?
    @property void window(Window window) { _window = window; }

	
}

/// widget list holder
struct WidgetList {
    protected Widget[] _list;
    protected int _count;
    /// returns count of items
    @property int count() const { return _count; }
    /// get item by index
    Widget get(int index) {
        assert(index >= 0 && index < _count, "child index out of range");
        return _list[index];
    }
    /// add item to list
    Widget add(Widget item) {
        if (_list.length <= _count) // resize
            _list.length = _list.length < 4 ? 4 : _list.length * 2;
        _list[_count++] = item;
        return item;
    }
    /// add item to list
    Widget insert(Widget item, int index = -1) {
        if (index > _count || index < 0)
            index = _count;
        if (_list.length <= _count) // resize
            _list.length = _list.length < 4 ? 4 : _list.length * 2;
        for (int i = _count; i > index; i--)
            _list[i] = _list[i - 1];
        _list[index] = item;
        _count++;
        return item;
    }
    /// find child index for item, return -1 if not found
    int indexOf(Widget item) {
        for (int i = 0; i < _count; i++)
            if (_list[i] == item)
                return i;
        return -1;
    }
    /// find child index for item by id, return -1 if not found
    int indexOf(string id) {
        for (int i = 0; i < _count; i++)
            if (_list[i].compareId(id))
                return i;
        return -1;
    }
    /// remove item from list, return removed item
    Widget remove(int index) {
        assert(index >= 0 && index < _count, "child index out of range");
        Widget item = _list[index];
        for (int i = index; i < _count - 1; i++)
            _list[i] = _list[i + 1];
        _count--;
        return item;
    }
    /// remove and destroy all items
    void clear() {
        for (int i = 0; i < _count; i++) {
            destroy(_list[i]);
            _list[i] = null;
        }
        _count = 0;
    }
    ~this() {
        clear();
    }
}

/// base class for widgets which have children
class WidgetGroup : Widget {

	this(string ID = null) {
		super(ID);
	}

    protected WidgetList _children;

    /// returns number of children of this widget
    @property override int childCount() { return _children.count; }
    /// returns child by index
    override Widget child(int index) { return _children.get(index); }
    /// adds child, returns added item
    override Widget addChild(Widget item) { return _children.add(item).parent(this); }
    /// removes child, returns removed item
    override Widget removeChild(int index) { 
        Widget res = _children.remove(index);
        if (res !is null)
            res.parent = null;
        return res;
    }
    /// removes child by ID, returns removed item
    override Widget removeChild(string ID) {
        Widget res = null;
        int index = _children.indexOf(ID);
        if (index < 0)
            return null;
        res = _children.remove(index); 
        if (res !is null)
            res.parent = null;
        return res;
    }
    /// returns index of widget in child list, -1 if passed widget is not a child of this widget
    override int childIndex(Widget item) { return _children.indexOf(item); }
}

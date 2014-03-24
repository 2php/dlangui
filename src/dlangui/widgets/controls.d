module dlangui.widgets.controls;

import dlangui.widgets.widget;



/// static text widget
class TextWidget : Widget {
    this(string ID = null) {
		super(ID);
        styleId = "TEXT";
    }
    protected dstring _text;
    /// get widget text
    override @property dstring text() { return _text; }
    /// set text to show
    override @property Widget text(dstring s) { 
        _text = s; 
        requestLayout();
		return this;
    }

    override void measure(int parentWidth, int parentHeight) { 
        FontRef font = font();
        Point sz = font.textSize(text);
        measuredContent(parentWidth, parentHeight, sz.x, sz.y);
    }

    bool onClick() {
        // override it
        Log.d("Button.onClick ", id);
        return false;
    }

    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        ClipRectSaver(buf, rc);
        applyPadding(rc);
        FontRef font = font();
        Point sz = font.textSize(text);
        applyAlign(rc, sz);
        font.drawText(buf, rc.left, rc.top, text, textColor);
    }
}

/// image widget
class ImageWidget : Widget {

    protected string _drawableId;
    protected DrawableRef _drawable;

    this(string ID = null, string drawableId = null) {
		super(ID);
        _drawableId = drawableId;
	}

    /// get drawable image id
    @property string drawableId() { return _drawableId; }
    /// set drawable image id
    @property ImageWidget drawableId(string id) { 
        _drawableId = id; 
        _drawable.clear();
        requestLayout();
        return this; 
    }
    /// get drawable
    @property ref DrawableRef drawable() {
        if (!_drawable.isNull)
            return _drawable;
        if (_drawableId !is null)
            _drawable = drawableCache.get(_drawableId);
        return _drawable;
    }
    /// set custom drawable (not one from resources)
    @property ImageWidget drawable(DrawableRef img) {
        _drawable = img;
        _drawableId = null;
        return this;
    }

    override void measure(int parentWidth, int parentHeight) { 
        DrawableRef img = drawable;
        int w = 0;
        int h = 0;
        if (!img.isNull) {
            w = img.width;
            h = img.height;
        }
        measuredContent(parentWidth, parentHeight, w, h);
    }
    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        ClipRectSaver(buf, rc);
        applyPadding(rc);
        DrawableRef img = drawable;
        if (!img.isNull) {
            Point sz;
            sz.x = img.width;
            sz.y = img.height;
            applyAlign(rc, sz);
            img.drawTo(buf, rc);
        }
    }
}

/// button with image only
class ImageButton : ImageWidget {
    this(string ID = null, string drawableId = null) {
        super(ID);
        styleId = "BUTTON";
        _drawableId = drawableId;
    }
}

class Button : Widget {
    protected dstring _text;
    override @property dstring text() { return _text; }
    override @property Widget text(dstring s) { _text = s; requestLayout(); return this; }
    this(string ID = null) {
		super(ID);
        styleId = "BUTTON";
    }

    override void measure(int parentWidth, int parentHeight) { 
        FontRef font = font();
        Point sz = font.textSize(text);
        measuredContent(parentWidth, parentHeight, sz.x, sz.y);
    }

	override void onDraw(DrawBuf buf) {
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        buf.fillRect(_pos, backgroundColor);
        applyPadding(rc);
        ClipRectSaver(buf, rc);
        FontRef font = font();
        Point sz = font.textSize(text);
        applyAlign(rc, sz);
        font.drawText(buf, rc.left, rc.top, text, textColor);
    }

}

/// scroll bar - either vertical or horizontal
class ScrollBar : WidgetGroup, OnClickHandler {
    protected ImageButton _btnBack;
    protected ImageButton _btnForward;
    protected ImageButton _indicator;
    protected Rect _scrollArea;
    protected int _btnSize;
    protected int _minIndicatorSize;
    protected int _minValue = 0;
    protected int _maxValue = 100;
    protected int _pageSize = 30;
    protected int _position = 20;

    class IndicatorButton : ImageButton {
        Point _dragStart;
        int _dragStartPosition;
        bool _dragging;
        Rect _dragStartRect;
        this(string resourceId) {
            super("INDICATOR", resourceId);
        }

        /// process mouse event; return true if event is processed by widget.
        override bool onMouseEvent(MouseEvent event) {
            // support onClick
            if (event.action == MouseAction.ButtonDown && event.button == MouseButton.Left) {
                setState(State.Pressed);
                _dragging = true;
                _dragStart.x = event.x;
                _dragStart.y = event.y;
                _dragStartPosition = _position;
                _dragStartRect = _pos;
                return true;
            }
            if (event.action == MouseAction.Move && _dragging) {
                int delta = _orientation == Orientation.Vertical ? event.y - _dragStart.y : event.x - _dragStart.x;
                Rect rc = _dragStartRect;
                int offset;
                int space;
                if (_orientation == Orientation.Vertical) {
                    rc.top += delta;
                    rc.bottom += delta;
                    if (rc.top < _scrollArea.top) {
                        rc.top = _scrollArea.top;
                        rc.bottom = _scrollArea.top + _dragStartRect.height;
                    } else if (rc.bottom > _scrollArea.bottom) {
                        rc.top = _scrollArea.top - _dragStartRect.height;
                        rc.bottom = _scrollArea.bottom;
                    }
                    offset = rc.top - _scrollArea.top;
                    space = _scrollArea.height - rc.height;
                } else {
                    rc.left += delta;
                    rc.right += delta;
                    if (rc.left < _scrollArea.left) {
                        rc.left = _scrollArea.left;
                        rc.right = _scrollArea.left + _dragStartRect.width;
                    } else if (rc.right > _scrollArea.right) {
                        rc.left = _scrollArea.right - _dragStartRect.width;
                        rc.right = _scrollArea.right;
                    }
                    offset = rc.left - _scrollArea.left;
                    space = _scrollArea.width - rc.width;
                }
                _pos = rc;
                int position = space > 0 ? _minValue + offset * (_maxValue - _minValue - _pageSize) / space : 0;
                invalidate();
                onIndicatorDragging(_dragStartPosition, position);
                return true;
            }
            if (event.action == MouseAction.ButtonUp && event.button == MouseButton.Left) {
                resetState(State.Pressed);
                if (_dragging) {

                    _dragging = false;
                }
                return true;
            }
            if (event.action == MouseAction.Cancel) {
                Log.d("IndicatorButton.onMouseEvent event.action == MouseAction.Cancel");
                resetState(State.Pressed);
                _dragging = false;
                return true;
            }
            return false;
        }

    }

    protected bool onIndicatorDragging(int initialPosition, int currentPosition) {
        _position = currentPosition;
        return true;
    }

    private bool calcButtonSizes(int availableSize, ref int spaceBackSize, ref int spaceForwardSize, ref int indicatorSize) {
        int dv = _maxValue - _minValue;
        if (_pageSize >= dv) {
            // full size
            spaceBackSize = spaceForwardSize = 0;
            indicatorSize = availableSize;
            return false;
        }
        if (dv < 0)
            dv = 0;
        indicatorSize = _pageSize * availableSize / dv;
        if (indicatorSize < _minIndicatorSize)
            indicatorSize = _minIndicatorSize;
        if (indicatorSize >= availableSize) {
            // full size
            spaceBackSize = spaceForwardSize = 0;
            indicatorSize = availableSize;
            return false;
        }
        int spaceLeft = availableSize - indicatorSize;
        int topv = _position - _minValue;
        int bottomv = _position + _pageSize - _minValue;
        if (topv < 0)
            topv = 0;
        if (bottomv > dv)
            bottomv = dv;
        bottomv = dv - bottomv;
        spaceBackSize = spaceLeft * topv / (topv + bottomv);
        spaceForwardSize = spaceLeft - spaceBackSize;
        return true;
    }

    protected Orientation _orientation = Orientation.Vertical;
    /// returns scrollbar orientation (Vertical, Horizontal)
    @property Orientation orientation() { return _orientation; }
    /// sets scrollbar orientation
    @property ScrollBar orientation(Orientation value) { 
        if (_orientation != value) {
            _orientation = value; 
            _btnBack.drawableId = _orientation == Orientation.Vertical ? "scrollbar_btn_up" : "scrollbar_btn_left";
            _btnForward.drawableId = _orientation == Orientation.Vertical ? "scrollbar_btn_down" : "scrollbar_btn_right";
            _indicator.drawableId = _orientation == Orientation.Vertical ? "scrollbar_indicator_vertical" : "scrollbar_indicator_horizontal";
            requestLayout(); 
        }
        return this; 
    }

    this(string ID = null, Orientation orient = Orientation.Vertical) {
		super(ID);
        styleId = "BUTTON";
        _orientation = orient;
        _btnBack = new ImageButton("BACK", _orientation == Orientation.Vertical ? "scrollbar_btn_up" : "scrollbar_btn_left");
        _btnForward = new ImageButton("FORWARD", _orientation == Orientation.Vertical ? "scrollbar_btn_down" : "scrollbar_btn_right");
        _indicator = new IndicatorButton(_orientation == Orientation.Vertical ? "scrollbar_indicator_vertical" : "scrollbar_indicator_horizontal");
        addChild(_btnBack);
        addChild(_btnForward);
        addChild(_indicator);
        _btnBack.onClickListener = &onClick;
        _btnForward.onClickListener = &onClick;
    }

    override void measure(int parentWidth, int parentHeight) { 
        Point sz;
        _btnBack.measure(parentWidth, parentHeight);
        _btnForward.measure(parentWidth, parentHeight);
        _indicator.measure(parentWidth, parentHeight);
        _btnSize = _btnBack.measuredWidth;
        _minIndicatorSize = _orientation == Orientation.Vertical ? _indicator.measuredHeight : _indicator.measuredWidth;
        if (_btnSize < _btnBack.measuredHeight)
            _btnSize = _btnBack.measuredHeight;
        if (_btnSize < 16)
            _btnSize = 16;
        if (_orientation == Orientation.Vertical) {
            // vertical
            sz.x = _btnSize;
            sz.y = _btnSize * 5; // min height
        } else {
            // horizontal
            sz.y = _btnSize;
            sz.x = _btnSize * 5; // min height
        }
        measuredContent(parentWidth, parentHeight, sz.x, sz.y);
    }

    override void layout(Rect rc) {
        applyMargins(rc);
        applyPadding(rc);
        Rect r;
        if (_orientation == Orientation.Vertical) {
            // vertical
            // buttons
            int backbtnpos = rc.top + _btnSize;
            int fwdbtnpos = rc.bottom - _btnSize;
            r = rc;
            r.bottom = backbtnpos;
            _btnBack.layout(r);
            r = rc;
            r.top = fwdbtnpos;
            _btnForward.layout(r);
            // indicator
            r = rc;
            r.top = backbtnpos;
            r.bottom = fwdbtnpos;
            _scrollArea = r;
            int spaceBackSize, spaceForwardSize, indicatorSize;
            bool indicatorVisible = calcButtonSizes(r.height, spaceBackSize, spaceForwardSize, indicatorSize);
            Rect irc = r;
            irc.top += spaceBackSize;
            irc.bottom -= spaceForwardSize;
            _indicator.layout(irc);
        } else {
            // horizontal
            int backbtnpos = rc.left + _btnSize;
            int fwdbtnpos = rc.right - _btnSize;
            r = rc;
            r.right = backbtnpos;
            _btnBack.layout(r);
            r = rc;
            r.left = fwdbtnpos;
            _btnForward.layout(r);
            // indicator
            r = rc;
            r.left = backbtnpos;
            r.right = fwdbtnpos;
            _scrollArea = r;
            int spaceBackSize, spaceForwardSize, indicatorSize;
            bool indicatorVisible = calcButtonSizes(r.width, spaceBackSize, spaceForwardSize, indicatorSize);
            Rect irc = r;
            irc.left += spaceBackSize;
            irc.right -= spaceForwardSize;
            _indicator.layout(irc);
        }
        _pos = rc;
        _needLayout = false;
    }

    override bool onClick(Widget source) {
        return true;
    }

    /// Draw widget at its position to buffer
    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        applyPadding(rc);
        ClipRectSaver(buf, rc);
        _btnForward.onDraw(buf);
        _btnBack.onDraw(buf);
        _indicator.onDraw(buf);
    }
}

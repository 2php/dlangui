module dlangui.platforms.common.platform;

public import dlangui.core.events;
import dlangui.widgets.widget;
import dlangui.graphics.drawbuf;
import std.file;
private import dlangui.graphics.gldrawbuf;

class Window {
    protected int _dx;
    protected int _dy;
    protected Widget _mainWidget;
    @property int width() { return _dx; }
    @property int height() { return _dy; }
    @property Widget mainWidget() { return _mainWidget; }
    @property void mainWidget(Widget widget) { 
        if (_mainWidget !is null)
            _mainWidget.window = null;
        _mainWidget = widget; 
        if (_mainWidget !is null)
            _mainWidget.window = this;
    }
    abstract void show();
    abstract @property string windowCaption();
    abstract @property void windowCaption(string caption);
    void onResize(int width, int height) {
        if (_dx == width && _dy == height)
            return;
        _dx = width;
        _dy = height;
        if (_mainWidget !is null) {
            _mainWidget.measure(_dx, _dy);
            _mainWidget.layout(Rect(0, 0, _dx, _dy));
        }
    }
    void onDraw(DrawBuf buf) {
        if (_mainWidget !is null) {
            _mainWidget.onDraw(buf);
        }
    }
	abstract bool onMouseEvent(MouseEvent event);
}

class Platform {
    static __gshared Platform _instance;
    static void setInstance(Platform instance) {
        _instance = instance;
    }
    static Platform instance() {
        return _instance;
    }
    abstract Window createWindow(string windowCaption, Window parent);
    abstract int enterMessageLoop();
}

version (USE_OPENGL) {
    private __gshared bool _OPENGL_ENABLED = false;
    /// check if hardware acceleration is enabled
    @property bool openglEnabled() { return _OPENGL_ENABLED; }
    /// call on app initialization if OpenGL support is detected
    void setOpenglEnabled() {
        _OPENGL_ENABLED = true;
	    glyphDestroyCallback = &onGlyphDestroyedCallback;
    }
}

version (Windows) {
    immutable char PATH_DELIMITER = '\\';
} else {
    immutable char PATH_DELIMITER = '/';
}

/// returns current executable path only, including last path delimiter
string exePath() {
    string path = thisExePath();
    int lastSlash = 0;
    for (int i = 0; i < path.length; i++)
        if (path[i] == PATH_DELIMITER)
            lastSlash = i;
    return path[0 .. lastSlash + 1];
}

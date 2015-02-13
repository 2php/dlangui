// Written in the D programming language.

/**

This module contains implementation of Win32 platform support

Provides Win32Window and Win32Platform classes.

Usually you don't need to use this module directly.


Synopsis:

----
import dlangui.platforms.windows.winapp;
----

Copyright: Vadim Lopatin, 2014
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
*/
module dlangui.platforms.windows.winapp;
version (USE_SDL) { } 
else version (Windows) {

import core.runtime;
import win32.windows;
import std.string;
import std.utf;
import std.stdio;
import std.algorithm;
import std.file;
import dlangui.platforms.common.platform;
import dlangui.platforms.windows.win32fonts;
import dlangui.platforms.windows.win32drawbuf;
import dlangui.widgets.styles;
import dlangui.widgets.widget;
import dlangui.graphics.drawbuf;
import dlangui.graphics.images;
import dlangui.graphics.fonts;
import dlangui.core.logger;
import dlangui.core.files;

version (USE_OPENGL) {
    import dlangui.graphics.glsupport;
}

// specify debug=DebugMouseEvents for logging mouse handling
// specify debug=DebugRedraw for logging drawing and layouts handling
// specify debug=DebugKeys for logging of key events

pragma(lib, "gdi32.lib");
pragma(lib, "user32.lib");

/// this function should be defined in user application!
extern (C) int UIAppMain(string[] args);

immutable WIN_CLASS_NAME = "DLANGUI_APP";

__gshared HINSTANCE _hInstance;
__gshared int _cmdShow;

version (USE_OPENGL) {
    bool setupPixelFormat(HDC hDC)
    {
        PIXELFORMATDESCRIPTOR pfd = {
            PIXELFORMATDESCRIPTOR.sizeof,  /* size */
            1,                              /* version */
            PFD_SUPPORT_OPENGL |
                PFD_DRAW_TO_WINDOW |
                PFD_DOUBLEBUFFER,               /* support double-buffering */
            PFD_TYPE_RGBA,                  /* color type */
            16,                             /* prefered color depth */
            0, 0, 0, 0, 0, 0,               /* color bits (ignored) */
            0,                              /* no alpha buffer */
            0,                              /* alpha bits (ignored) */
            0,                              /* no accumulation buffer */
            0, 0, 0, 0,                     /* accum bits (ignored) */
            16,                             /* depth buffer */
            0,                              /* no stencil buffer */
            0,                              /* no auxiliary buffers */
            0,                              /* main layer PFD_MAIN_PLANE */
            0,                              /* reserved */
            0, 0, 0,                        /* no layer, visible, damage masks */
        };
        int pixelFormat;

        pixelFormat = ChoosePixelFormat(hDC, &pfd);
        if (pixelFormat == 0) {
            Log.e("ChoosePixelFormat failed.");
            return false;
        }

        if (SetPixelFormat(hDC, pixelFormat, &pfd) != TRUE) {
            Log.e("SetPixelFormat failed.");
            return false;
        }
        return true;
    }

    HPALETTE setupPalette(HDC hDC)
    {
        import core.stdc.stdlib;
        HPALETTE hPalette = NULL;
        int pixelFormat = GetPixelFormat(hDC);
        PIXELFORMATDESCRIPTOR pfd;
        LOGPALETTE* pPal;
        int paletteSize;

        DescribePixelFormat(hDC, pixelFormat, PIXELFORMATDESCRIPTOR.sizeof, &pfd);

        if (pfd.dwFlags & PFD_NEED_PALETTE) {
            paletteSize = 1 << pfd.cColorBits;
        } else {
            return null;
        }

        pPal = cast(LOGPALETTE*)
            malloc(LOGPALETTE.sizeof + paletteSize * PALETTEENTRY.sizeof);
        pPal.palVersion = 0x300;
        pPal.palNumEntries = cast(ushort)paletteSize;

        /* build a simple RGB color palette */
        {
            int redMask = (1 << pfd.cRedBits) - 1;
            int greenMask = (1 << pfd.cGreenBits) - 1;
            int blueMask = (1 << pfd.cBlueBits) - 1;
            int i;

            for (i=0; i<paletteSize; ++i) {
                pPal.palPalEntry[i].peRed = cast(ubyte)(
                    (((i >> pfd.cRedShift) & redMask) * 255) / redMask);
                pPal.palPalEntry[i].peGreen = cast(ubyte)(
                    (((i >> pfd.cGreenShift) & greenMask) * 255) / greenMask);
                pPal.palPalEntry[i].peBlue = cast(ubyte)(
                    (((i >> pfd.cBlueShift) & blueMask) * 255) / blueMask);
                pPal.palPalEntry[i].peFlags = 0;
            }
        }

        hPalette = CreatePalette(pPal);
        free(pPal);

        if (hPalette) {
            SelectPalette(hDC, hPalette, FALSE);
            RealizePalette(hDC);
        }

        return hPalette;
    }

    private __gshared bool DERELICT_GL3_RELOADED = false;
}

const uint CUSTOM_MESSAGE_ID = WM_USER + 1;

class Win32Window : Window {
    Win32Platform _platform;

    HWND _hwnd;
    version (USE_OPENGL) {
        HGLRC _hGLRC; // opengl context
        HPALETTE _hPalette;
        GLSupport _gl;
    }
    dstring _caption;
    Win32ColorDrawBuf _drawbuf;
    bool useOpengl;
    uint _flags;
    this(Win32Platform platform, dstring windowCaption, Window parent, uint flags, uint width = 0, uint height = 0) {
        Win32Window w32parent = cast(Win32Window)parent;
        HWND parenthwnd = w32parent ? w32parent._hwnd : null;
        _dx = width;
        _dy = height;
        if (!_dx)
            _dx = 600;
        if (!_dy)
            _dy = 400;
        _platform = platform;
        version (USE_OPENGL) {
            _gl = new GLSupport();
        }
        _caption = windowCaption;
        _flags = flags;
        uint ws = WS_CLIPCHILDREN | WS_CLIPSIBLINGS;
        if (flags & WindowFlag.Resizable)
            ws |= WS_OVERLAPPEDWINDOW;
        else
            ws |= WS_OVERLAPPED | WS_CAPTION | WS_CAPTION | WS_BORDER | WS_SYSMENU;
        //if (flags & WindowFlag.Fullscreen)
        //    ws |= SDL_WINDOW_FULLSCREEN;
        _hwnd = CreateWindowW(toUTF16z(WIN_CLASS_NAME),      // window class name
                            toUTF16z(windowCaption),  // window caption
                            ws,  // window style
                            CW_USEDEFAULT,        // initial x position
                            CW_USEDEFAULT,        // initial y position
                            _dx,        // initial x size
                            _dy,        // initial y size
                            parenthwnd,                 // parent window handle
                            null,                 // window menu handle
                            _hInstance,           // program instance handle
                            cast(void*)this);                // creation parameters
        version (USE_OPENGL) {
            import derelict.opengl3.wgl;

            /* initialize OpenGL rendering */
            HDC hDC = GetDC(_hwnd);

            if (!DERELICT_GL3_RELOADED || openglEnabled) {
                if (setupPixelFormat(hDC)) {
                    _hPalette = setupPalette(hDC);
                    _hGLRC = wglCreateContext(hDC);
                    if (_hGLRC) {

                        wglMakeCurrent(hDC, _hGLRC);
                        _glSupport = _gl;

                        if (!DERELICT_GL3_RELOADED) {
                            // run this code only once
                            DERELICT_GL3_RELOADED = true;
                            try {
                                import derelict.opengl3.gl3;
                                DerelictGL3.reload();
                                // successful
                                if (glSupport.initShaders()) {
                                    setOpenglEnabled();
                                    useOpengl = true;
                                } else {
                                    Log.e("Failed to compile shaders");
                                }
                            } catch (Exception e) {
                                Log.e("Derelict exception", e);
                            }
                        } else {
						    if (glSupport.initShaders()) {
							    setOpenglEnabled();
							    useOpengl = true;
						    } else {
							    Log.e("Failed to compile shaders");
						    }
                        }
                    }
                } else {
                    Log.e("Pixelformat failed");
                    // disable GL
                    DERELICT_GL3_RELOADED = true;
                }
            }
        }
    }

    version (USE_OPENGL) {
        private void paintUsingOpenGL() {
            // hack to stop infinite WM_PAINT loop
            PAINTSTRUCT ps;
            HDC hdc2 = BeginPaint(_hwnd, &ps);
            EndPaint(_hwnd, &ps);


            import derelict.opengl3.gl3;
            import derelict.opengl3.wgl;
            import dlangui.graphics.gldrawbuf;
            //Log.d("onPaint() start drawing opengl viewport: ", _dx, "x", _dy);
            //PAINTSTRUCT ps;
            //HDC hdc = BeginPaint(_hwnd, &ps);
            //scope(exit) EndPaint(_hwnd, &ps);
            HDC hdc = GetDC(_hwnd);
            wglMakeCurrent(hdc, _hGLRC);
            _glSupport = _gl;
            glDisable(GL_DEPTH_TEST);
            glViewport(0, 0, _dx, _dy);
			float a = 1.0f;
			float r = ((_backgroundColor >> 16) & 255) / 255.0f;
			float g = ((_backgroundColor >> 8) & 255) / 255.0f;
			float b = ((_backgroundColor >> 0) & 255) / 255.0f;
            glClearColor(r, g, b, a);
            glClear(GL_COLOR_BUFFER_BIT);

            GLDrawBuf buf = new GLDrawBuf(_dx, _dy, false);
            buf.beforeDrawing();
            static if (false) {
                // for testing for render
                buf.fillRect(Rect(100, 100, 200, 200), 0x704020);
                buf.fillRect(Rect(40, 70, 100, 120), 0x000000);
                buf.fillRect(Rect(80, 80, 150, 150), 0x80008000); // green
                drawableCache.get("exit").drawTo(buf, Rect(300, 100, 364, 164));
                drawableCache.get("btn_default_pressed").drawTo(buf, Rect(300, 200, 564, 264));
                drawableCache.get("btn_default_normal").drawTo(buf, Rect(300, 0, 400, 50));
                drawableCache.get("btn_default_selected").drawTo(buf, Rect(0, 0, 100, 50));
                FontRef fnt = currentTheme.font;
                fnt.drawText(buf, 40, 40, "Some Text 1234567890 !@#$^*", 0x80FF0000);
            } else {
                onDraw(buf);
            }
            buf.afterDrawing();
            SwapBuffers(hdc);
            wglMakeCurrent(hdc, null);
        }
    }

    ~this() {
        debug Log.d("Window destructor");
        version (USE_OPENGL) {
            import derelict.opengl3.wgl;
            if (_hGLRC) {
			    glSupport.uninitShaders();
                destroy(_glSupport);
                _glSupport = null;
                _gl = null;
                wglMakeCurrent (null, null) ;
                wglDeleteContext(_hGLRC);
                _hGLRC = null;
            }
        }
        if (_hwnd)
            DestroyWindow(_hwnd);
        _hwnd = null;
    }

    /// post event to handle in UI thread (this method can be used from background thread)
    override void postEvent(CustomEvent event) {
        super.postEvent(event);
        PostMessageW(_hwnd, CUSTOM_MESSAGE_ID, 0, event.uniqueId);
    }

    /// set handler for files dropped to app window
    override @property Window onFilesDropped(void delegate(string[]) handler) { 
        super.onFilesDropped(handler);
        DragAcceptFiles(_hwnd, handler ? TRUE : FALSE);
        return this; 
    }

    private long _nextExpectedTimerTs;
    private UINT_PTR _timerId = 1;

    /// schedule timer for interval in milliseconds - call window.onTimer when finished
    override protected void scheduleSystemTimer(long intervalMillis) {
        if (intervalMillis < 10)
            intervalMillis = 10;
        long nextts = currentTimeMillis + intervalMillis;
        if (_timerId && _nextExpectedTimerTs && _nextExpectedTimerTs < nextts + 10)
            return; // don't reschedule timer, timer event will be received soon
        if (_hwnd) {
			//_timerId = 
            SetTimer(_hwnd, _timerId, cast(uint)intervalMillis, null);
            _nextExpectedTimerTs = nextts;
        }
    }

    void handleTimer(UINT_PTR timerId) {
		//Log.d("handleTimer id=", timerId);
		if (timerId == _timerId) {
			KillTimer(_hwnd, timerId);
			//_timerId = 0;
			_nextExpectedTimerTs = 0;
			onTimer();
		}
    }


    Win32ColorDrawBuf getDrawBuf() {
        //RECT rect;
        //GetClientRect(_hwnd, &rect);
        //int dx = rect.right - rect.left;
        //int dy = rect.bottom - rect.top;
        if (_drawbuf is null)
            _drawbuf = new Win32ColorDrawBuf(_dx, _dy);
        else
            _drawbuf.resize(_dx, _dy);
        _drawbuf.resetClipping();
        return _drawbuf;
    }
    override void show() {
        ReleaseCapture();
        if (!(_flags & WindowFlag.Resizable) && _mainWidget) {
            _mainWidget.measure(SIZE_UNSPECIFIED, SIZE_UNSPECIFIED);
            int dx = _mainWidget.measuredWidth;
            int dy = _mainWidget.measuredHeight;
            dx += 2 * GetSystemMetrics(SM_CXDLGFRAME);
            dy += GetSystemMetrics(SM_CYCAPTION) + 2 * GetSystemMetrics(SM_CYDLGFRAME);
            // TODO: ensure size less than screen size
            SetWindowPos(_hwnd, HWND_TOP, 0, 0, dx, dy, SWP_NOMOVE| SWP_SHOWWINDOW);
        } else {
            ShowWindow(_hwnd, SW_SHOWNORMAL);
        }
        if (_mainWidget)
            _mainWidget.setFocus();
        SetFocus(_hwnd);
        //UpdateWindow(_hwnd);
    }

	override @property dstring windowCaption() {
		return _caption;
	}

	override @property void windowCaption(dstring caption) {
		_caption = caption;
		if (_hwnd) {
			Log.d("windowCaption ", caption);
			SetWindowTextW(_hwnd, toUTF16z(_caption));
		}
	}
    void onCreate() {
        Log.d("Window onCreate");
        _platform.onWindowCreated(_hwnd, this);
    }
    void onDestroy() {
        Log.d("Window onDestroy");
        _platform.onWindowDestroyed(_hwnd, this);
    }

	/// close window
	override void close() {
		Log.d("Window.close()");
		_platform.closeWindow(this);
	}

    HICON _icon;

    uint _cursorType;

    HANDLE[ushort] _cursorCache;

    HANDLE loadCursor(ushort id) {
        if (id in _cursorCache)
            return _cursorCache[id];
        HANDLE h = LoadCursor(null, MAKEINTRESOURCE(id));
        _cursorCache[id] = h;
        return h;
    }

    void onSetCursorType() {
        HANDLE winCursor = null;
        switch (_cursorType) {
            case CursorType.None:
                winCursor = null;
                break;
            case CursorType.Parent:
                break;
            case CursorType.Arrow:
                winCursor = loadCursor(IDC_ARROW);
                break;
            case CursorType.IBeam:
                winCursor = loadCursor(IDC_IBEAM);
                break;
            case CursorType.Wait:
                winCursor = loadCursor(IDC_WAIT);
                break;
            case CursorType.Crosshair:
                winCursor = loadCursor(IDC_CROSS);
                break;
            case CursorType.WaitArrow:
                winCursor = loadCursor(IDC_APPSTARTING);
                break;
            case CursorType.SizeNWSE:
                winCursor = loadCursor(IDC_SIZENWSE);
                break;
            case CursorType.SizeNESW:
                winCursor = loadCursor(IDC_SIZENESW);
                break;
            case CursorType.SizeWE:
                winCursor = loadCursor(IDC_SIZEWE);
                break;
            case CursorType.SizeNS:
                winCursor = loadCursor(IDC_SIZENS);
                break;
            case CursorType.SizeAll:
                winCursor = loadCursor(IDC_SIZEALL);
                break;
            case CursorType.No:
                winCursor = loadCursor(IDC_NO);
                break;
            case CursorType.Hand:
                winCursor = loadCursor(IDC_HAND);
                break;
            default:
                break;
        }
        SetCursor(winCursor);
    }

	/// sets cursor type for window
	override protected void setCursorType(uint cursorType) {
		// override to support different mouse cursors
        _cursorType = cursorType;
        onSetCursorType();
	}

	/// sets window icon
	@property override void windowIcon(DrawBufRef buf) {
        if (_icon)
            DestroyIcon(_icon);
        _icon = null;
		ColorDrawBuf icon = cast(ColorDrawBuf)buf.get;
		if (!icon) {
			Log.e("Trying to set null icon for window");
			return;
		}
        Win32ColorDrawBuf resizedicon = new Win32ColorDrawBuf(icon, 32, 32);
        resizedicon.invertAlpha();
        ICONINFO ii;
        HBITMAP mask = resizedicon.createTransparencyBitmap();
        HBITMAP color = resizedicon.destroyLeavingBitmap();
        ii.fIcon = TRUE;
        ii.xHotspot = 0;
        ii.yHotspot = 0;
        ii.hbmMask = mask;
        ii.hbmColor = color;
        _icon = CreateIconIndirect(&ii);
        if (_icon) {
            SendMessageW(_hwnd, WM_SETICON, ICON_SMALL, cast(LPARAM)_icon);
            SendMessageW(_hwnd, WM_SETICON, ICON_BIG, cast(LPARAM)_icon);
        } else {
            Log.e("failed to create icon");
        }
        if (mask)
            DeleteObject(mask);
        DeleteObject(color);
	}

    private void paintUsingGDI() {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(_hwnd, &ps);
        scope(exit) EndPaint(_hwnd, &ps);

        Win32ColorDrawBuf buf = getDrawBuf();
        buf.fill(_backgroundColor);
        onDraw(buf);
        buf.drawTo(hdc, 0, 0);
    }

    void onPaint() {
        debug(DebugRedraw) Log.d("onPaint()");
        long paintStart = currentTimeMillis;
        version (USE_OPENGL) {
            if (useOpengl && _hGLRC) {
                paintUsingOpenGL();
            } else {
                paintUsingGDI();
            }
        } else {
            paintUsingGDI();
        }
        long paintEnd = currentTimeMillis;
        debug(DebugRedraw) Log.d("WM_PAINT handling took ", paintEnd - paintStart, " ms");
    }

	protected ButtonDetails _lbutton;
	protected ButtonDetails _mbutton;
	protected ButtonDetails _rbutton;

    private bool _mouseTracking;
	private bool onMouse(uint message, uint flags, short x, short y) {
		debug(DebugMouseEvents) Log.d("Win32 Mouse Message ", message, " flags=", flags, " x=", x, " y=", y);
        MouseButton button = MouseButton.None;
        MouseAction action = MouseAction.ButtonDown;
        ButtonDetails * pbuttonDetails = null;
        short wheelDelta = 0;
        switch (message) {
            case WM_MOUSEMOVE:
                action = MouseAction.Move;
                break;
            case WM_LBUTTONDOWN:
                action = MouseAction.ButtonDown;
                button = MouseButton.Left;
                pbuttonDetails = &_lbutton;
                SetFocus(_hwnd);
                break;
            case WM_RBUTTONDOWN:
                action = MouseAction.ButtonDown;
                button = MouseButton.Right;
                pbuttonDetails = &_rbutton;
                SetFocus(_hwnd);
                break;
            case WM_MBUTTONDOWN:
                action = MouseAction.ButtonDown;
                button = MouseButton.Middle;
                pbuttonDetails = &_mbutton;
                SetFocus(_hwnd);
                break;
            case WM_LBUTTONUP:
                action = MouseAction.ButtonUp;
                button = MouseButton.Left;
                pbuttonDetails = &_lbutton;
                break;
            case WM_RBUTTONUP:
                action = MouseAction.ButtonUp;
                button = MouseButton.Right;
                pbuttonDetails = &_rbutton;
                break;
            case WM_MBUTTONUP:
                action = MouseAction.ButtonUp;
                button = MouseButton.Middle;
                pbuttonDetails = &_mbutton;
                break;
            case WM_MOUSELEAVE:
                debug(DebugMouseEvents) Log.d("WM_MOUSELEAVE");
                action = MouseAction.Leave;
                break;
            case WM_MOUSEWHEEL:
                {
                    action = MouseAction.Wheel;
                    wheelDelta = (cast(short)(flags >> 16)) / 120;
                    POINT pt;
                    pt.x = x;
                    pt.y = y;
                    ScreenToClient(_hwnd, &pt);
                    x = cast(short)pt.x;
                    y = cast(short)pt.y;
                }
                break;
            default:
                // unsupported event
                return false;
        }
        if (action == MouseAction.ButtonDown) {
            pbuttonDetails.down(x, y, cast(ushort)flags);
        } else if (action == MouseAction.ButtonUp) {
            pbuttonDetails.up(x, y, cast(ushort)flags);
        }
        if (((message == WM_MOUSELEAVE) || (x < 0 || y < 0 || x >= _dx || y >= _dy)) && _mouseTracking) {
            if (!isMouseCaptured() || (!_lbutton.isDown && !_rbutton.isDown && !_mbutton.isDown)) {
                action = MouseAction.Leave;
                debug(DebugMouseEvents) Log.d("Win32Window.onMouse releasing capture");
                _mouseTracking = false;
                ReleaseCapture();
            }
        }
        if (message != WM_MOUSELEAVE && !_mouseTracking) {
            if (x >=0 && y >= 0 && x < _dx && y < _dy) {
                debug(DebugMouseEvents) Log.d("Win32Window.onMouse Setting capture");
                _mouseTracking = true;
                SetCapture(_hwnd);
            }
        }
        MouseEvent event = new MouseEvent(action, button, cast(ushort)flags, x, y, wheelDelta);
        event.lbutton = _lbutton;
        event.rbutton = _rbutton;
        event.mbutton = _mbutton;
		bool res = dispatchMouseEvent(event);
        if (res) {
            //Log.v("Calling update() after mouse event");
            update();
        }
        return res;
	}


    protected uint _keyFlags;

    protected void updateKeyFlags(KeyAction action, KeyFlag flag) {
        if (action == KeyAction.KeyDown)
            _keyFlags |= flag;
        else
            _keyFlags &= ~flag;
    }

    bool onKey(KeyAction action, uint keyCode, int repeatCount, dchar character = 0, bool syskey = false) {
        KeyEvent event;
        if (syskey)
            _keyFlags |= KeyFlag.Alt;
        //else
        //    _keyFlags &= ~KeyFlag.Alt;
        if (action == KeyAction.KeyDown || action == KeyAction.KeyUp) {
            switch(keyCode) {
                case KeyCode.SHIFT:
                    updateKeyFlags(action, KeyFlag.Shift);
                    break;
                case KeyCode.CONTROL:
                    updateKeyFlags(action, KeyFlag.Control);
                    break;
                case KeyCode.ALT:
                    updateKeyFlags(action, KeyFlag.Alt);
                    break;
                default:
                    updateKeyFlags((GetKeyState(VK_CONTROL) & 0x8000) != 0 ? KeyAction.KeyDown : KeyAction.KeyUp, KeyFlag.Control);
                    updateKeyFlags((GetKeyState(VK_SHIFT) & 0x8000) != 0 ? KeyAction.KeyDown : KeyAction.KeyUp, KeyFlag.Shift);
                    updateKeyFlags((GetKeyState(VK_MENU) & 0x8000) != 0 ? KeyAction.KeyDown : KeyAction.KeyUp, KeyFlag.Alt);
                    break;
            }
            if (keyCode == 0xBF)
                keyCode = KeyCode.KEY_DIVIDE;
            event = new KeyEvent(action, keyCode, _keyFlags);
        } else if (action == KeyAction.Text && character != 0) {
            if (_keyFlags & (KeyFlag.Control | KeyFlag.Alt)) {
                if (character >= 1 && character <= 26) {
                    event = new KeyEvent(action, KeyCode.KEY_A + character - 1, _keyFlags);
                }
            } else {
                dchar[] text;
                text ~= character;
                event = new KeyEvent(action, 0, _keyFlags, cast(dstring)text);
            }
        }
        bool res = false;
        if (event !is null) {
            res = dispatchKeyEvent(event);
        }
        if (res) {
            debug(DebugRedraw) Log.d("Calling update() after key event");
            update();
        }
        return res;
    }

    /// request window redraw
    override void invalidate() {
        InvalidateRect(_hwnd, null, FALSE);
		//UpdateWindow(_hwnd);
    }

    /// after drawing, call to schedule redraw if animation is active
    override void scheduleAnimation() {
        invalidate();
    }

}

class Win32Platform : Platform {
    this() {
    }
    bool registerWndClass() {
        //MSG  msg;
        WNDCLASSW wndclass;

        wndclass.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
        wndclass.lpfnWndProc   = &WndProc;
        wndclass.cbClsExtra    = 0;
        wndclass.cbWndExtra    = 0;
        wndclass.hInstance     = _hInstance;
        wndclass.hIcon         = LoadIcon(null, IDI_APPLICATION);
        wndclass.hCursor       = LoadCursor(null, IDC_ARROW);
        wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
        wndclass.lpszMenuName  = null;
        wndclass.lpszClassName = toUTF16z(WIN_CLASS_NAME);

        if(!RegisterClassW(&wndclass))
        {
            return false;
        }
        HDC dc = CreateCompatibleDC(NULL);
        SCREEN_DPI = GetDeviceCaps(dc, LOGPIXELSY);
        DeleteObject(dc);

        return true;
    }
    override int enterMessageLoop() {
        MSG  msg;
        while (GetMessage(&msg, null, 0, 0))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        return msg.wParam;
    }
    private Win32Window[ulong] _windowMap;
    /// add window to window map
    void onWindowCreated(HWND hwnd, Win32Window window) {
        _windowMap[cast(ulong)hwnd] = window;
    }
    /// remove window from window map, returns true if there are some more windows left in map
    bool onWindowDestroyed(HWND hwnd, Win32Window window) {
        Win32Window wnd = getWindow(hwnd);
        if (wnd) {
            _windowMap.remove(cast(ulong)hwnd);
            destroy(window);
        }
        return _windowMap.length > 0;
    }
    /// returns number of currently active windows
    @property int windowCount() {
        return cast(int)_windowMap.length;
    }
    /// returns window instance by HWND
    Win32Window getWindow(HWND hwnd) {
        if ((cast(ulong)hwnd) in _windowMap)
            return _windowMap[cast(ulong)hwnd];
        return null;
    }
    override Window createWindow(dstring windowCaption, Window parent, uint flags = WindowFlag.Resizable, uint width = 0, uint height = 0) {
        setDefaultLanguageAndThemeIfNecessary();
        return new Win32Window(this, windowCaption, parent, flags, width, height);
    }

	/// calls request layout for all windows
	override void requestLayout() {
		foreach(w; _windowMap) {
			w.requestLayout();
			w.invalidate();
		}
	}

	Win32Window _windowToClose;

	/// close window
	override void closeWindow(Window w) {
		Win32Window window = cast(Win32Window)w;
		_windowToClose = window;
	}

    /// retrieves text from clipboard (when mouseBuffer == true, use mouse selection clipboard - under linux)
    override dstring getClipboardText(bool mouseBuffer = false) {
        dstring res = null;
        if (mouseBuffer)
            return res; // not supporetd under win32
        if (!IsClipboardFormatAvailable(CF_UNICODETEXT))
            return res; 
        if (!OpenClipboard(NULL)) 
            return res; 

        HGLOBAL hglb = GetClipboardData(CF_UNICODETEXT); 
        if (hglb != NULL) 
        { 
            LPWSTR lptstr = cast(LPWSTR)GlobalLock(hglb); 
            if (lptstr != NULL) 
            { 
                wstring w = fromWStringz(lptstr);
                res = toUTF32(w);

                GlobalUnlock(hglb); 
            } 
        } 

        CloseClipboard();
        //Log.d("getClipboardText(", res, ")");
        return res;
    }

    /// sets text to clipboard (when mouseBuffer == true, use mouse selection clipboard - under linux)
    override void setClipboardText(dstring text, bool mouseBuffer = false) {
        //Log.d("setClipboardText(", text, ")");
        if (text.length < 1 || mouseBuffer)
            return;
        if (!OpenClipboard(NULL))
            return; 
        EmptyClipboard();
        wstring w = toUTF16(text);
        HGLOBAL hglbCopy = GlobalAlloc(GMEM_MOVEABLE, 
                           (w.length + 1) * TCHAR.sizeof); 
        if (hglbCopy == NULL) { 
            CloseClipboard(); 
            return; 
        }
        LPWSTR lptstrCopy = cast(LPWSTR)GlobalLock(hglbCopy);
        for (int i = 0; i < w.length; i++) {
            lptstrCopy[i] = w[i];
        }
        lptstrCopy[w.length] = 0;
        GlobalUnlock(hglbCopy);
        SetClipboardData(CF_UNICODETEXT, hglbCopy); 

        CloseClipboard();
    }

}

extern(Windows)
int DLANGUIWinMain(void* hInstance, void* hPrevInstance,
            char* lpCmdLine, int nCmdShow) {
    int result;

    try
    {
        Runtime.initialize();
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow);
        Runtime.terminate();
    }
    catch (Throwable e) // catch any uncaught exceptions
    {
        MessageBoxW(null, toUTF16z(e.toString()), "Error",
                    MB_OK | MB_ICONEXCLAMATION);
        result = 0;     // failed
    }

    return result;
}

string[] splitCmdLine(string line) {
    string[] res;
    int start = 0;
    bool insideQuotes = false;
    for (int i = 0; i <= line.length; i++) {
        char ch = i < line.length ? line[i] : 0;
        if (ch == '\"') {
            if (insideQuotes) {
                if (i > start)
                    res ~= line[start .. i];
                start = i + 1;
                insideQuotes = false;
            } else {
                insideQuotes = true;
                start = i + 1;
            }
        } else if (!insideQuotes && (ch == ' ' || ch == '\t' || ch == 0)) {
            if (i > start) {
                res ~= line[start .. i];
            }
            start = i + 1;
        }
    }
    return res;
}

private __gshared Win32Platform w32platform;

int myWinMain(void* hInstance, void* hPrevInstance, char* lpCmdLine, int iCmdShow)
{
	Log.setFileLogger(std.stdio.File("ui.log", "w"));
	debug {
        Log.setLogLevel(LogLevel.Trace);
    } else {
        Log.setLogLevel(LogLevel.Info);
    }
    Log.d("myWinMain()");
    string basePath = exePath();
    Log.i("Current executable: ", exePath());
    string cmdline = fromStringz(lpCmdLine).dup;
    Log.i("Command line: ", cmdline);
    string[] args = splitCmdLine(cmdline);
    Log.i("Command line params: ", args);

    _cmdShow = iCmdShow;
    _hInstance = hInstance;

    w32platform = new Win32Platform();
    if (!w32platform.registerWndClass()) {
        MessageBoxA(null, "This program requires Windows NT!", "DLANGUI App".toStringz, MB_ICONERROR);
        return 0;
    }
    Platform.setInstance(w32platform);



    try {
        /// testing freetype font manager
        version(USE_FREETYPE) {
            import dlangui.graphics.ftfonts;
            // trying to create font manager
            FreeTypeFontManager ftfontMan = new FreeTypeFontManager();

            import win32.shlobj;
            string fontsPath = "c:\\Windows\\Fonts\\";
            static if (true) { // SHGetFolderPathW not found in shell32.lib
                WCHAR[MAX_PATH] szPath;
                static if (false) {
                    const CSIDL_FLAG_NO_ALIAS = 0x1000;
                    const CSIDL_FLAG_DONT_UNEXPAND = 0x2000;
                    if(SUCCEEDED(SHGetFolderPathW(NULL,
                                                  CSIDL_FONTS|CSIDL_FLAG_NO_ALIAS|CSIDL_FLAG_DONT_UNEXPAND,
                                                  NULL,
                                                  0,
                                                  szPath.ptr)))
                    {
                        fontsPath = toUTF8(fromWStringz(szPath));
                    }
                } else {
                    if (GetWindowsDirectory(szPath.ptr, MAX_PATH - 1)) {
                        fontsPath = toUTF8(fromWStringz(szPath));
                        Log.i("Windows directory: ", fontsPath);
                        fontsPath ~= "\\Fonts\\";
                        Log.i("Fonts directory: ", fontsPath);
                    }
                }
            }
            ftfontMan.registerFont(fontsPath ~ "arial.ttf",     FontFamily.SansSerif, "Arial", false, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "arialbd.ttf",   FontFamily.SansSerif, "Arial", false, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "arialbi.ttf",   FontFamily.SansSerif, "Arial", true, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "ariali.ttf",    FontFamily.SansSerif, "Arial", true, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "cour.ttf",      FontFamily.MonoSpace, "Courier New", false, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "courbd.ttf",    FontFamily.MonoSpace, "Courier New", false, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "courbi.ttf",    FontFamily.MonoSpace, "Courier New", true, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "couri.ttf",     FontFamily.MonoSpace, "Courier New", true, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "times.ttf",     FontFamily.Serif, "Times New Roman", false, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "timesbd.ttf",   FontFamily.Serif, "Times New Roman", false, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "timesbi.ttf",   FontFamily.Serif, "Times New Roman", true, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "timesi.ttf",    FontFamily.Serif, "Times New Roman", true, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "consola.ttf",   FontFamily.MonoSpace, "Consolas", false, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "consolab.ttf",  FontFamily.MonoSpace, "Consolas", false, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "consolai.ttf",  FontFamily.MonoSpace, "Consolas", true, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "consolaz.ttf",  FontFamily.MonoSpace, "Consolas", true, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "verdana.ttf",   FontFamily.SansSerif, "Verdana", false, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "verdanab.ttf",  FontFamily.SansSerif, "Verdana", false, FontWeight.Bold);
            ftfontMan.registerFont(fontsPath ~ "verdanai.ttf",  FontFamily.SansSerif, "Verdana", true, FontWeight.Normal);
            ftfontMan.registerFont(fontsPath ~ "verdanaz.ttf",  FontFamily.SansSerif, "Verdana", true, FontWeight.Bold);
            if (ftfontMan.registeredFontCount()) {
                FontManager.instance = ftfontMan;
            } else {
                Log.w("No fonts registered in FreeType font manager. Disabling FreeType.");
                destroy(ftfontMan);
            }
        }
    } catch (Exception e) {
        Log.e("Cannot create FreeTypeFontManager - falling back to win32");
    }

    // use Win32 font manager
    if (FontManager.instance is null) {
	    FontManager.instance = new Win32FontManager();
    }

	currentTheme = createDefaultTheme();

    version (USE_OPENGL) {
        import derelict.opengl3.gl3;
        DerelictGL3.load();

        // just to check OpenGL context
        Log.i("Trying to setup OpenGL context");
        Win32Window tmpWindow = new Win32Window(w32platform, ""d, null, 0);
        destroy(tmpWindow);
        if (openglEnabled)
            Log.i("OpenGL support is enabled");
        else
            Log.w("OpenGL support is disabled");
        // process messages
        platform.enterMessageLoop();
    }

    // Load versions 1.2+ and all supported ARB and EXT extensions.

    Log.i("Entering UIAppMain: ", args);
    int result = UIAppMain(args);
    Log.i("UIAppMain returned ", result);
    return result;
}


extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    RECT rect;

    void * p = cast(void*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    Win32Window windowParam = p is null ? null : cast(Win32Window)(p);
    Win32Window window = w32platform.getWindow(hwnd);
    if (windowParam !is null && window !is null)
        assert(window is windowParam);
    if (window is null && windowParam !is null) {
        Log.e("Cannot find window in map by HWND");
    }

    switch (message)
    {
        case WM_CREATE:
            {
                CREATESTRUCT * pcreateStruct = cast(CREATESTRUCT*)lParam;
                window = cast(Win32Window)pcreateStruct.lpCreateParams;
                void * ptr = cast(void*) window;
                SetWindowLongPtr(hwnd, GWLP_USERDATA, cast(LONG_PTR)ptr);
                window._hwnd = hwnd;
                window.onCreate();
            }
            return 0;
        case WM_DESTROY:
            if (window !is null)
                window.onDestroy();
            if (w32platform.windowCount == 0)
                PostQuitMessage(0);
            return 0;
        case WM_WINDOWPOSCHANGED:
            {
                if (window !is null) {
                    WINDOWPOS * pos = cast(WINDOWPOS*)lParam;
                    Log.d("WM_WINDOWPOSCHANGED: ", *pos);
                    GetClientRect(hwnd, &rect);
                    //window.onResize(pos.cx, pos.cy);
                    //if (!(pos.flags & 0x8000)) { //SWP_NOACTIVATE)) {
                    //if (pos.x > -30000) {
                        int dx = rect.right - rect.left;
                        int dy = rect.bottom - rect.top;
                        window.onResize(dx, dy);
                        InvalidateRect(hwnd, null, FALSE);
                    //}
                    //}
                }
            }
            return 0;
        case CUSTOM_MESSAGE_ID:
            if (window !is null) {
                window.handlePostedEvent(cast(uint)lParam);
            }
            return 1;
        case WM_ERASEBKGND:
            // processed
            return 1;
        case WM_PAINT:
            {
                if (window !is null)
                    window.onPaint();
            }
            return 0; // processed
        case WM_SETCURSOR:
            {
                if (window !is null) {
                    if (LOWORD(lParam) == HTCLIENT) {
                        window.onSetCursorType();
                        return 1;
                    }
                }
            }
            break;
        case WM_MOUSELEAVE:
		case WM_MOUSEMOVE:
		case WM_LBUTTONDOWN:
		case WM_MBUTTONDOWN:
		case WM_RBUTTONDOWN:
		case WM_LBUTTONUP:
		case WM_MBUTTONUP:
		case WM_RBUTTONUP:
        case WM_MOUSEWHEEL:
			if (window !is null) {
				if (window.onMouse(message, cast(uint)wParam, cast(short)(lParam & 0xFFFF), cast(short)((lParam >> 16) & 0xFFFF)))
                    return 0; // processed
            }
            // not processed - default handling
            return DefWindowProc(hwnd, message, wParam, lParam);
        case WM_KEYDOWN:
        case WM_SYSKEYDOWN:
        case WM_KEYUP:
        case WM_SYSKEYUP:
			if (window !is null) {
                int repeatCount = lParam & 0xFFFF;
				if (window.onKey(message == WM_KEYDOWN || message == WM_SYSKEYDOWN ? KeyAction.KeyDown : KeyAction.KeyUp, wParam, repeatCount, 0, message == WM_SYSKEYUP || message == WM_SYSKEYDOWN))
                    return 0; // processed
            }
            break;
        case WM_UNICHAR:
			if (window !is null) {
                int repeatCount = lParam & 0xFFFF;
				if (window.onKey(KeyAction.Text, wParam, repeatCount, wParam == UNICODE_NOCHAR ? 0 : wParam))
                    return 1; // processed
                return 1;
            }
            break;
        case WM_CHAR:
			if (window !is null) {
                int repeatCount = lParam & 0xFFFF;
				if (window.onKey(KeyAction.Text, wParam, repeatCount, wParam == UNICODE_NOCHAR ? 0 : wParam))
                    return 1; // processed
                return 1;
            }
            break;
        case WM_TIMER:
			if (window !is null) {
				window.handleTimer(wParam);
                return 0;
            }
            break;
        case WM_DROPFILES:
			if (window !is null) {
                HDROP hdrop = cast(HDROP)wParam;
                string[] files;
                wchar[] buf;
                auto count = DragQueryFileW(hdrop, 0xFFFFFFFF, cast(wchar*)NULL, 0);
                for (int i = 0; i < count; i++) {
                    auto sz = DragQueryFileW(hdrop, i, cast(wchar*)NULL, 0); 
                    buf.length = sz + 2;
                    sz = DragQueryFileW(hdrop, i, buf.ptr, sz + 1); 
                    files ~= toUTF8(buf[0..sz]);
                }
                if (files.length)
                    window.handleDroppedFiles(files);
                DragFinish(hdrop);
            }
            return 0;
        case WM_GETMINMAXINFO:
        case WM_NCCREATE:
        case WM_NCCALCSIZE:
        default:
            //Log.d("Unhandled message ", message);
            break;
    }
    if (w32platform._windowToClose) {
        Win32Window wnd = w32platform._windowToClose;
        w32platform._windowToClose = null;
        destroy(wnd);
        //HWND w = w32platform._windowToClose._hwnd;
        //CloseWindow(w);
    }
    return DefWindowProc(hwnd, message, wParam, lParam);
}

//===========================================
// end of version(Windows)
//===========================================
} 



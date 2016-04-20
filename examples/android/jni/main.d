/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import core.stdc.stdlib : malloc;
import core.stdc.string : memset;
import dlangui.core.logger;

import dlangui.widgets.styles;
import dlangui.graphics.drawbuf;
//import dlangui.widgets.widget;
import dlangui.platforms.common.platform;

import EGL.eglplatform : EGLint;
import EGL.egl, GLES.gl;

import android.input, android.looper : ALooper_pollAll;
import android.native_window : ANativeWindow_setBuffersGeometry;
import android.sensor, android.log, android.android_native_app_glue;


/**
 * Window abstraction layer. Widgets can be shown only inside window.
 * 
 */
class AndroidWindow : Window {
	// Abstract methods : override in platform implementatino
	
	/// show window
	override void show() {
		// TODO
	}

	protected dstring _caption;
	/// returns window caption
	override @property dstring windowCaption() {
		return _caption;
	}
	/// sets window caption
	override @property void windowCaption(dstring caption) {
		_caption = caption;
	}
	/// sets window icon
	override @property void windowIcon(DrawBufRef icon) {
		// not supported
	}
	/// request window redraw
	override void invalidate() {
	}
	/// close window
	override void close() {
	}

	protected AndroidPlatform _platform;
	this(AndroidPlatform platform) {
		super();
		_platform = platform;
	}
	~this() {
	}
	
	/// after drawing, call to schedule redraw if animation is active
	override void scheduleAnimation() {
		// override if necessary
		// TODO
	}

}

/**
 * Platform abstraction layer.
 * 
 * Represents application.
 * 
 * 
 * 
 */
class AndroidPlatform : Platform {

	protected AndroidWindow[] _windows;
	protected AndroidWindow _activeWindow;

	protected android_app* _appstate;
	this(android_app* state) {
		_appstate = state;
	}

	/**
     * create window
     * Args:
     *         windowCaption = window caption text
     *         parent = parent Window, or null if no parent
     *         flags = WindowFlag bit set, combination of Resizable, Modal, Fullscreen
     *      width = window width 
     *      height = window height
     * 
     * Window w/o Resizable nor Fullscreen will be created with size based on measurement of its content widget
     */
	override Window createWindow(dstring windowCaption, Window parent, uint flags = WindowFlag.Resizable, uint width = 0, uint height = 0) {
		AndroidWindow w = new AndroidWindow(this);
		_windows ~= w;
		_activeWindow = w;
		return w;
	}
	
	/**
     * close window
     * 
     * Closes window earlier created with createWindow()
     */
	override  void closeWindow(Window w) {
		import std.algorithm : remove;
		for (int i = 0; i < _windows.length; i++) {
			if (_windows[i] is w) {
				_windows = _windows.remove(i);
				break;
			}
		}
		_activeWindow = (_windows.length > 0 ? _windows[$ - 1] : null);
	}

	/**
     * Starts application message loop.
     * 
     * When returned from this method, application is shutting down.
     */
	override int enterMessageLoop() {
		// TODO:
		return 0;
	}

	protected dstring _clipboardText;
	/// retrieves text from clipboard (when mouseBuffer == true, use mouse selection clipboard - under linux)
	override dstring getClipboardText(bool mouseBuffer = false) {
		return _clipboardText;
	}

	/// sets text to clipboard (when mouseBuffer == true, use mouse selection clipboard - under linux)
	override void setClipboardText(dstring text, bool mouseBuffer = false) {
		_clipboardText = text;
	}
	
	/// calls request layout for all windows
	override void requestLayout() {
	}
	
	/// handle theme change: e.g. reload some themed resources
	override void onThemeChanged() {
		// override and call dispatchThemeChange for all windows
	}
	
}



/**
 * Our saved state data.
 */
struct saved_state {
    float angle;
    float x;
    float y;
}

/**
 * Shared state for our app.
 */
struct engine {
    android_app* app;

    ASensorManager* sensorManager;
    const(ASensor)* accelerometerSensor;
    ASensorEventQueue* sensorEventQueue;

    int animating;
    EGLDisplay display;
    EGLSurface surface;
    EGLContext context;
    int width;
    int height;
    saved_state state;
}

/**
 * Initialize an EGL context for the current display.
 */
int engine_init_display(engine* engine) {
    // initialize OpenGL ES and EGL

    /*
     * Here specify the attributes of the desired configuration.
     * Below, we select an EGLConfig with at least 8 bits per color
     * component compatible with on-screen windows
     */
    const(EGLint)[9] attribs = [
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_NONE
    ];
    EGLint w, h, dummy, format;
    EGLint numConfigs;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

    eglInitialize(display, null, null);

    /* Here, the application chooses the configuration it desires. In this
     * sample, we have a very simplified selection process, where we pick
     * the first EGLConfig that matches our criteria */
    eglChooseConfig(display, attribs.ptr, &config, 1, &numConfigs);

    /* EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
     * guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
     * As soon as we picked a EGLConfig, we can safely reconfigure the
     * ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID. */
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);

    ANativeWindow_setBuffersGeometry(engine.app.window, 0, 0, format);

    surface = eglCreateWindowSurface(display, config, engine.app.window, null);
    context = eglCreateContext(display, config, null, null);

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE) {
        LOGW("Unable to eglMakeCurrent");
        return -1;
    }

    eglQuerySurface(display, surface, EGL_WIDTH, &w);
    eglQuerySurface(display, surface, EGL_HEIGHT, &h);

    engine.display = display;
    engine.context = context;
    engine.surface = surface;
    engine.width = w;
    engine.height = h;
    engine.state.angle = 0;

    // Initialize GL state.
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
    glEnable(GL_CULL_FACE);
    //glShadeModel(GL_SMOOTH);
    glDisable(GL_DEPTH_TEST);

    return 0;
}

/**
 * Just the current frame in the display.
 */
void engine_draw_frame(engine* engine) {
    if (engine.display == null) {
        // No display.
        return;
    }

    // Just fill the screen with a color.
    glClearColor(engine.state.x/engine.width, engine.state.angle,
            engine.state.y/engine.height, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    eglSwapBuffers(engine.display, engine.surface);
}

/**
 * Tear down the EGL context currently associated with the display.
 */
void engine_term_display(engine* engine) {
    if (engine.display != EGL_NO_DISPLAY) {
        eglMakeCurrent(engine.display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (engine.context != EGL_NO_CONTEXT) {
            eglDestroyContext(engine.display, engine.context);
        }
        if (engine.surface != EGL_NO_SURFACE) {
            eglDestroySurface(engine.display, engine.surface);
        }
        eglTerminate(engine.display);
    }
    engine.animating = 0;
    engine.display = EGL_NO_DISPLAY;
    engine.context = EGL_NO_CONTEXT;
    engine.surface = EGL_NO_SURFACE;
}

/**
 * Process the next input event.
 */
extern(C) int engine_handle_input(android_app* app, AInputEvent* event) {
    engine* engine = cast(engine*)app.userData;
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        engine.animating = 1;
        engine.state.x = AMotionEvent_getX(event, 0);
        engine.state.y = AMotionEvent_getY(event, 0);
        return 1;
    }
    return 0;
}

/**
 * Process the next main command.
 */
extern(C) void engine_handle_cmd(android_app* app, int cmd) {
    engine* engine = cast(engine*)app.userData;
    switch (cmd) {
        case APP_CMD_SAVE_STATE:
            // The system has asked us to save our current state.  Do so.
            engine.app.savedState = malloc(saved_state.sizeof);
            *(cast(saved_state*)engine.app.savedState) = engine.state;
            engine.app.savedStateSize = saved_state.sizeof;
            break;
        case APP_CMD_INIT_WINDOW:
            // The window is being shown, get it ready.
            if (engine.app.window != null) {
                engine_init_display(engine);
                engine_draw_frame(engine);
            }
            break;
        case APP_CMD_TERM_WINDOW:
            // The window is being hidden or closed, clean it up.
            engine_term_display(engine);
            break;
        case APP_CMD_GAINED_FOCUS:
            // When our app gains focus, we start monitoring the accelerometer.
            if (engine.accelerometerSensor != null) {
                ASensorEventQueue_enableSensor(engine.sensorEventQueue,
                        engine.accelerometerSensor);
                // We'd like to get 60 events per second (in us).
                ASensorEventQueue_setEventRate(engine.sensorEventQueue,
                        engine.accelerometerSensor, (1000L/60)*1000);
            }
            break;
        case APP_CMD_LOST_FOCUS:
            // When our app loses focus, we stop monitoring the accelerometer.
            // This is to avoid consuming battery while not being used.
            if (engine.accelerometerSensor != null) {
                ASensorEventQueue_disableSensor(engine.sensorEventQueue,
                        engine.accelerometerSensor);
            }
            // Also stop animating.
            engine.animating = 0;
            engine_draw_frame(engine);
            break;
        default:
            break;
    }
}

void main(){}

__gshared AndroidPlatform _platform;

/**
 * This is the main entry point of a native application that is using
 * android_native_app_glue.  It runs in its own thread, with its own
 * event loop for receiving input events and doing other things.
 */
extern (C) void android_main(android_app* state) {
	//import dlangui.platforms.common.startup : initLogs, initFontManager, initResourceManagers, ;
	LOGI("Inside android_main");
    initLogs();
    Log.i("Testing logger - Log.i");
    Log.fi("Testing logger - Log.fi %d %s", 12345, "asdfgh");

    if (!initFontManager()) {
        Log.e("******************************************************************");
        Log.e("No font files found!!!");
        Log.e("Currently, only hardcoded font paths implemented.");
        Log.e("******************************************************************");
        assert(false);
    }
    initResourceManagers();

    currentTheme = createDefaultTheme();

	_platform = new AndroidPlatform(state);
	Platform.setInstance(_platform);


    engine engine;

    // Make sure glue isn't stripped.
    app_dummy();

    memset(&engine, 0, engine.sizeof);
    state.userData = &engine;
    state.onAppCmd = &engine_handle_cmd;
    state.onInputEvent = &engine_handle_input;
    engine.app = state;

    // Prepare to monitor accelerometer
    engine.sensorManager = ASensorManager_getInstance();
    engine.accelerometerSensor = ASensorManager_getDefaultSensor(engine.sensorManager,
            ASENSOR_TYPE_ACCELEROMETER);
    engine.sensorEventQueue = ASensorManager_createEventQueue(engine.sensorManager,
            state.looper, LOOPER_ID_USER, null, null);

    if (state.savedState != null) {
        // We are starting with a previous saved state; restore from it.
        engine.state = *cast(saved_state*)state.savedState;
    }

    // loop waiting for stuff to do.

    while (1) {
        // Read all pending events.
        int ident;
        int events;
        android_poll_source* source;

        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        while ((ident=ALooper_pollAll(engine.animating ? 0 : -1, null, &events,
                cast(void**)&source)) >= 0) {

            // Process this event.
            if (source != null) {
                source.process(state, source);
            }

            // If a sensor has data, process it now.
            if (ident == LOOPER_ID_USER) {
                if (engine.accelerometerSensor != null) {
                    ASensorEvent event;
                    while (ASensorEventQueue_getEvents(engine.sensorEventQueue,
                            &event, 1) > 0) {
                        LOGI("accelerometer: x=%f y=%f z=%f",
                                event.acceleration.x, event.acceleration.y,
                                event.acceleration.z);
                    }
                }
            }

            // Check if we are exiting.
            if (state.destroyRequested != 0) {
                Log.d("Destroying Android platform");
                Platform.setInstance(null);

                releaseResourcesOnAppExit();

                Log.d("Exiting main");
                
                engine_term_display(&engine);
                return;
            }
        }

        if (engine.animating) {
            // Done with events; draw next animation frame.
            engine.state.angle += .01f;
            if (engine.state.angle > 1) {
                engine.state.angle = 0;
            }

            // Drawing is throttled to the screen update rate, so there
            // is no need to do timing here.
            engine_draw_frame(&engine);
        }
    }
}


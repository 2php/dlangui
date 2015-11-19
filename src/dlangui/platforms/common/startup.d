﻿module dlangui.platforms.common.startup;

public import dlangui.core.events;
public import dlangui.widgets.styles;
public import dlangui.graphics.fonts;
public import dlangui.graphics.resources;
public import dlangui.widgets.widget;

version(USE_FREETYPE) {
	public import dlangui.graphics.ftfonts;
}

version (Windows) {
	
	/// initialize font manager - default implementation
	/// On win32 - first it tries to init freetype, and falls back to win32 fonts.
	/// On linux/mac - tries to init freetype with some hardcoded font paths
	extern(C) bool initFontManager() {
		import win32.windows;
		import std.utf;
		import dlangui.platforms.windows.win32fonts;
		try {
			/// testing freetype font manager
			version(USE_FREETYPE) {
				Log.v("Trying to init FreeType font manager");
				
				import dlangui.graphics.ftfonts;
				// trying to create font manager
				Log.v("Creating FreeTypeFontManager");
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
				Log.v("Registering fonts");
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
		return true;
	}
	
} else {
	import dlangui.graphics.ftfonts;
	bool registerFonts(FreeTypeFontManager ft, string path) {
		import std.file;
		if (!exists(path) || !isDir(path))
			return false;
		ft.registerFont(path ~ "DejaVuSans.ttf", FontFamily.SansSerif, "DejaVuSans", false, FontWeight.Normal);
		ft.registerFont(path ~ "DejaVuSans-Bold.ttf", FontFamily.SansSerif, "DejaVuSans", false, FontWeight.Bold);
		ft.registerFont(path ~ "DejaVuSans-Oblique.ttf", FontFamily.SansSerif, "DejaVuSans", true, FontWeight.Normal);
		ft.registerFont(path ~ "DejaVuSans-BoldOblique.ttf", FontFamily.SansSerif, "DejaVuSans", true, FontWeight.Bold);
		ft.registerFont(path ~ "DejaVuSansMono.ttf", FontFamily.MonoSpace, "DejaVuSansMono", false, FontWeight.Normal);
		ft.registerFont(path ~ "DejaVuSansMono-Bold.ttf", FontFamily.MonoSpace, "DejaVuSansMono", false, FontWeight.Bold);
		ft.registerFont(path ~ "DejaVuSansMono-Oblique.ttf", FontFamily.MonoSpace, "DejaVuSansMono", true, FontWeight.Normal);
		ft.registerFont(path ~ "DejaVuSansMono-BoldOblique.ttf", FontFamily.MonoSpace, "DejaVuSansMono", true, FontWeight.Bold);
		return true;
	}
	
	/// initialize font manager - default implementation
	/// On win32 - first it tries to init freetype, and falls back to win32 fonts.
	/// On linux/mac - tries to init freetype with some hardcoded font paths
	extern(C) bool initFontManager() {
		FreeTypeFontManager ft = new FreeTypeFontManager();
		
		if (!registerFontConfigFonts(ft)) {
			// TODO: use FontConfig
			Log.w("No fonts found using FontConfig. Trying hardcoded paths.");
			ft.registerFonts("/usr/share/fonts/truetype/dejavu/");
			ft.registerFonts("/usr/share/fonts/TTF/");
			ft.registerFonts("/usr/share/fonts/dejavu/");
			ft.registerFonts("/usr/share/fonts/truetype/ttf-dejavu/"); // let it compile on Debian Wheezy
			version(OSX) {
				ft.registerFont("/Library/Fonts/Arial.ttf", FontFamily.SansSerif, "Arial", false, FontWeight.Normal);
				ft.registerFont("/Library/Fonts/Arial Bold.ttf", FontFamily.SansSerif, "Arial", false, FontWeight.Bold);
				ft.registerFont("/Library/Fonts/Arial Italic.ttf", FontFamily.SansSerif, "Arial", true, FontWeight.Normal);
				ft.registerFont("/Library/Fonts/Arial Bold Italic.ttf", FontFamily.SansSerif, "Arial", true, FontWeight.Bold);
				//ft.registerFont("/Library/Fonts/Arial Narrow.ttf", FontFamily.SansSerif, "Arial Narrow", false, FontWeight.Normal);
				//ft.registerFont("/Library/Fonts/Arial Narrow Bold.ttf", FontFamily.SansSerif, "Arial Narrow", false, FontWeight.Bold);
				//ft.registerFont("/Library/Fonts/Arial Narrow Italic.ttf", FontFamily.SansSerif, "Arial Narrow", true, FontWeight.Normal);
				//ft.registerFont("/Library/Fonts/Arial Narrow Bold Italic.ttf", FontFamily.SansSerif, "Arial Narrow", true, FontWeight.Bold);
				ft.registerFont("/Library/Fonts/Courier New.ttf", FontFamily.MonoSpace, "Courier New", false, FontWeight.Normal);
				ft.registerFont("/Library/Fonts/Courier New Bold.ttf", FontFamily.MonoSpace, "Courier New", false, FontWeight.Bold);
				ft.registerFont("/Library/Fonts/Courier New Italic.ttf", FontFamily.MonoSpace, "Courier New", true, FontWeight.Normal);
				ft.registerFont("/Library/Fonts/Courier New Bold Italic.ttf", FontFamily.MonoSpace, "Courier New", true, FontWeight.Bold);
				ft.registerFont("/Library/Fonts/Georgia.ttf", FontFamily.Serif, "Georgia", false, FontWeight.Normal);
				ft.registerFont("/Library/Fonts/Georgia Bold.ttf", FontFamily.Serif, "Georgia", false, FontWeight.Bold);
				ft.registerFont("/Library/Fonts/Georgia Italic.ttf", FontFamily.Serif, "Georgia", true, FontWeight.Normal);
				ft.registerFont("/Library/Fonts/Georgia Bold Italic.ttf", FontFamily.Serif, "Georgia", true, FontWeight.Bold);
			}
		}
		
		if (!ft.registeredFontCount)
			return false;
		
		FontManager.instance = ft;
		return true;
	}
}


/// initialize logging (for win32 - to file ui.log, for other platforms - stderr; log level is TRACE for debug builds, and WARN for release builds)
extern (C) void initLogs() {
	version (Windows) {
		debug {
			Log.setFileLogger(new std.stdio.File("ui.log", "w"));
		} else {
			// no logging unless version ForceLogs is set
			version(ForceLogs) {
				Log.setFileLogger(new std.stdio.File("ui.log", "w"));
				Log.i("Logging to file ui.log");
			}
		}
	} else {
		Log.setStderrLogger();
	}
	debug {
		Log.setLogLevel(LogLevel.Trace);
	} else {
		version(ForceLogs) {
			Log.setLogLevel(LogLevel.Trace);
			Log.i("Log level: trace");
		} else {
			Log.setLogLevel(LogLevel.Warn);
			Log.i("Log level: warn");
		}
	}
	Log.i("Logger is initialized");
}

/// call this when all resources are supposed to be freed to report counts of non-freed resources by type
extern (C) void releaseResourcesOnAppExit() {
	
	//
	debug setAppShuttingDownFlag();
	
	debug {
		if (Widget.instanceCount() > 0) {
			Log.e("Non-zero Widget instance count when exiting: ", Widget.instanceCount);
		}
	}
	
	currentTheme = null;
	drawableCache = null;
	imageCache = null;
	FontManager.instance = null;
	
	debug {
		if (DrawBuf.instanceCount > 0) {
			Log.e("Non-zero DrawBuf instance count when exiting: ", DrawBuf.instanceCount);
		}
		if (Style.instanceCount > 0) {
			Log.e("Non-zero Style instance count when exiting: ", Style.instanceCount);
		}
		if (ImageDrawable.instanceCount > 0) {
			Log.e("Non-zero ImageDrawable instance count when exiting: ", ImageDrawable.instanceCount);
		}
		if (Drawable.instanceCount > 0) {
			Log.e("Non-zero Drawable instance count when exiting: ", Drawable.instanceCount);
		}
		version (USE_FREETYPE) {
			import dlangui.graphics.ftfonts;
			if (FreeTypeFontFile.instanceCount > 0) {
				Log.e("Non-zero FreeTypeFontFile instance count when exiting: ", FreeTypeFontFile.instanceCount);
			}
			if (FreeTypeFont.instanceCount > 0) {
				Log.e("Non-zero FreeTypeFont instance count when exiting: ", FreeTypeFont.instanceCount);
			}
		}
	}
}

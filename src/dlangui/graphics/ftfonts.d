/// freetype fonts support
module dlangui.graphics.ftfonts;

import dlangui.graphics.fonts;

import derelict.freetype.ft;
private import dlangui.core.logger;
private import std.algorithm;
private import std.file;
private import std.string;
private import std.utf;

private struct FontDef {
    immutable FontFamily _family;
    immutable string _face;
	immutable bool _italic;
	immutable int _weight;
	@property FontFamily family() { return _family; }
	@property string face() { return _face; }
	@property bool italic() { return _italic; }
	@property int weight() { return _weight; }
	this(FontFamily family, string face, bool italic, int weight) {
		_family = family;
		_face = face;
		_italic = italic;
        _weight = weight;
	}
    const bool opEquals(ref const FontDef v) {
        return _family == v._family && _italic == v._italic && _weight == v._weight && _face.equal(v._face);
    }
    const hash_t toHash() {
        hash_t res = 123;
        res = res * 31 + cast(hash_t)_italic;
        res = res * 31 + cast(hash_t)_weight;
        res = res * 31 + cast(hash_t)_family;
        res = res * 31 + typeid(_face).getHash(&_face);
        return res;
    }
}

private class FontFileItem {
	private FontList _activeFonts;
    private FT_Library _library;
    private FontDef _def;
    string[] _filenames;
    @property ref FontDef def() { return _def; }
    @property string[] filenames() { return _filenames; }
    @property FT_Library library() { return _library; }
    void addFile(string fn) {
        // check for duplicate entry
        foreach (ref string existing; _filenames)
            if (fn.equal(existing))
                return;
        _filenames ~= fn;
    }
    this(FT_Library library, ref FontDef def) {
        _library = library;
        _def = def;
    }

    private FontRef _nullFontRef;
    ref FontRef get(int size) {
        int index = _activeFonts.find(size);
        if (index >= 0)
            return _activeFonts.get(index);
        FreeTypeFont font = new FreeTypeFont(this, size);
        if (!font.create()) {
            destroy(font);
            return _nullFontRef;
        }
        return _activeFonts.add(font);
    }

}

private class FreeTypeFontFile {
    private string _filename;
    private string _faceName;
    private FT_Library    _library;
    private FT_Face       _face;
    private FT_GlyphSlot  _slot;
    private FT_Matrix     _matrix;                 /* transformation matrix */

    @property FT_Library library() { return _library; }

    private int _height;
    private int _size;
    private int _baseline;
    private int _weight;
    private bool _italic;

    /// filename
    @property string filename() { return _filename; }
    // properties as detected after opening of file
    @property string face() { return _faceName; }
    @property int height() { return _height; }
    @property int size() { return _size; }
    @property int baseline() { return _baseline; }
    @property int weight() { return _weight; }
    @property bool italic() { return _italic; }

	private static int _instanceCount;
    this(FT_Library library, string filename) {
        _library = library;
        _filename = filename;
        _matrix.xx = 0x10000;
        _matrix.yy = 0x10000;
        _matrix.xy = 0;
        _matrix.yx = 0;
		Log.d("Created FreeTypeFontFile, count=", ++_instanceCount);
    }

	~this() {
        clear();
		Log.d("Destroyed FreeTypeFontFile, count=", --_instanceCount);
    }

    private static string familyName(FT_Face face)
    {
        string faceName = fromStringz(face.family_name);
        string styleName = fromStringz(face.style_name);
        if (faceName.equal("Arial") && styleName.equal("Narrow"))
            faceName ~= " Narrow";
        else if (styleName.equal("Condensed"))
            faceName ~= " Condensed";
        return faceName;
    }

    /// open face with specified size
    bool open(int size, int index = 0) {
        int error = FT_New_Face( _library, _filename.toStringz, index, &_face); /* create face object */
        if (error)
            return false;
        if ( _filename.endsWith(".pfb") || _filename.endsWith(".pfa") ) {
        	string kernFile = _filename[0 .. $ - 4];
            if (exists(kernFile ~ ".afm")) {
        		kernFile ~= ".afm";
            } else if (exists(kernFile ~ ".pfm" )) {
        		kernFile ~= ".pfm";
        	} else {
        		kernFile.clear();
        	}
        	if (kernFile.length > 0)
        		error = FT_Attach_File(_face, kernFile.toStringz);
        }
        Log.d("Font file opened successfully");
        _slot = _face.glyph;
        _faceName = familyName(_face);
        error = FT_Set_Pixel_Sizes(
                _face,    /* handle to face object */
                0,        /* pixel_width           */
                size );  /* pixel_height          */
        if (error) {
            clear();
            return false;
        }
        _height = cast(int)(_face.size.metrics.height >> 6);
        _size = size;
        _baseline = _height + cast(int)(_face.size.metrics.descender >> 6);
        _weight = _face.style_flags & FT_STYLE_FLAG_BOLD ? FontWeight.Bold : FontWeight.Normal;
        _italic = _face.style_flags & FT_STYLE_FLAG_ITALIC ? true : false;
        Log.d("Opened font face=", _faceName, " height=", _height, " size=", size, " weight=", weight, " italic=", italic);
        return true; // successfully opened
    }

    static static dchar getReplacementChar(dchar code) {
        switch (code) {
            case UNICODE_SOFT_HYPHEN_CODE:
                return '-';
            case 0x0401: // CYRILLIC CAPITAL LETTER IO
                return 0x0415; //CYRILLIC CAPITAL LETTER IE
            case 0x0451: // CYRILLIC SMALL LETTER IO
                return 0x0435; // CYRILLIC SMALL LETTER IE
            case UNICODE_NO_BREAK_SPACE:
                return ' ';
            case 0x2010:
            case 0x2011:
            case 0x2012:
            case 0x2013:
            case 0x2014:
            case 0x2015:
                return '-';
            case 0x2018:
            case 0x2019:
            case 0x201a:
            case 0x201b:
                return '\'';
            case 0x201c:
            case 0x201d:
            case 0x201e:
            case 0x201f:
            case 0x00ab:
            case 0x00bb:
                return '\"';
            case 0x2039:
                return '<';
            case 0x203A:
                return '>';
            case 0x2044:
                return '/';
            case 0x2022: // css_lst_disc:
                return '*';
            case 0x26AA: // css_lst_disc:
            case 0x25E6: // css_lst_disc:
            case 0x25CF: // css_lst_disc:
                return 'o';
            case 0x25CB: // css_lst_circle:
                return '*';
            case 0x25A0: // css_lst_square:
                return '-';
            default:
                return 0;
        }
    }

    /// find glyph index for character
    FT_UInt getCharIndex(dchar code, dchar def_char = 0) {
        if ( code=='\t' )
            code = ' ';
        FT_UInt ch_glyph_index = FT_Get_Char_Index(_face, code);
        if (ch_glyph_index == 0) {
            dchar replacement = getReplacementChar(code);
            if (replacement)
                ch_glyph_index = FT_Get_Char_Index(_face, replacement);
            if (ch_glyph_index == 0 && def_char)
                ch_glyph_index = FT_Get_Char_Index( _face, def_char );
        }
        return ch_glyph_index;
    }

    /// retrieve glyph information, filling glyph struct; returns false if glyph not found
    bool getGlyphInfo(dchar code, ref Glyph glyph, dchar def_char, bool withImage = true)
    {
        //FONT_GUARD
        int glyph_index = getCharIndex(code, def_char);
        int flags = FT_LOAD_DEFAULT;
        const bool _drawMonochrome = false;
        flags |= (!_drawMonochrome ? FT_LOAD_TARGET_NORMAL : FT_LOAD_TARGET_MONO);
        if (withImage)
            flags |= FT_LOAD_RENDER;
        //if (_hintingMode == HINTING_MODE_AUTOHINT)
        //    flags |= FT_LOAD_FORCE_AUTOHINT;
        //else if (_hintingMode == HINTING_MODE_DISABLED)
        //    flags |= FT_LOAD_NO_AUTOHINT | FT_LOAD_NO_HINTING;
        int error = FT_Load_Glyph(
                                  _face,          /* handle to face object */
                                  glyph_index,   /* glyph index           */
                                  flags );  /* load flags, see below */
        if ( error )
            return false;
        glyph.lastUsage = 1;
        glyph.blackBoxX = cast(ubyte)(_slot.metrics.width >> 6);
        glyph.blackBoxY = cast(ubyte)(_slot.metrics.height >> 6);
        glyph.originX =   cast(byte)(_slot.metrics.horiBearingX >> 6);
        glyph.originY =   cast(byte)(_slot.metrics.horiBearingY >> 6);
        glyph.width =     cast(ubyte)(myabs(cast(int)(_slot.metrics.horiAdvance)) >> 6);
        if (withImage) {
            FT_Bitmap*  bitmap = &_slot.bitmap;
            ubyte w = cast(ubyte)(bitmap.width);
            ubyte h = cast(ubyte)(bitmap.rows);
            glyph.blackBoxX = w;
            glyph.blackBoxY = h;
            int sz = w * cast(int)h;
            if (sz > 0) {
                glyph.glyph = new ubyte[sz];
                for (int i = 0; i < sz; i++)
                    glyph.glyph[i] = bitmap.buffer[i];
            }
        }
        return true;
    }

    @property bool isNull() {
        return (_face is null);
    }

    void clear() {
        if (_face !is null)
            FT_Done_Face(_face);
        _face = null;
    }

}

/**
* Font implementation based on Win32 API system fonts.
*/
class FreeTypeFont : Font {
    private FontFileItem _fontItem;
    private FreeTypeFontFile[] _files;

	static int _instanceCount;
	/// need to call create() after construction to initialize font
    this(FontFileItem item, int size) {
        _fontItem = item;
        _size = size;
        _height = size;
		Log.d("Created font, count=", ++_instanceCount);
    }

	/// do cleanup
	~this() {
		clear();
		Log.d("Destroyed font, count=", --_instanceCount);
	}
	
    private int _size;
    private int _height;

	private GlyphCache _glyphCache;


	/// cleanup resources
    override void clear() {
        foreach(ref FreeTypeFontFile file; _files) {
            destroy(file);
            file = null;
        }
        _files.clear();
    }

	uint getGlyphIndex(dchar code)
	{
        return 0;
	}

    /// find glyph index for character
    bool findGlyph(dchar code, dchar def_char, ref FT_UInt index, ref FreeTypeFontFile file) {
        foreach(FreeTypeFontFile f; _files) {
            index = f.getCharIndex(code, def_char);
            if (index != 0) {
                file = f;
                return true;
            }
        }
        return false;
    }

    private Glyph tmpGlyphInfo;
	override Glyph * getCharGlyph(dchar ch, bool withImage = true) {
        if (ch > 0xFFFF) // do not support unicode chars above 0xFFFF - due to cache limitations
            return null;
		Glyph * found = _glyphCache.find(cast(ushort)ch);
		if (found !is null)
			return found;
        FT_UInt index;
        FreeTypeFontFile file;
        if (!findGlyph(ch, 0, index, file)) {
            if (!findGlyph(ch, '?', index, file))
                return null;
        }
        if (!file.getGlyphInfo(ch, tmpGlyphInfo, 0, withImage))
            return null;
        if (withImage)
		    return _glyphCache.put(cast(ushort)ch, &tmpGlyphInfo);
        return &tmpGlyphInfo;
	}

	// draw text string to buffer
	override void drawText(DrawBuf buf, int x, int y, const dchar[] text, uint color) {
		int[] widths;
        int bl = baseline;
        int xx = 0;
		for (int i = 0; i < text.length; i++) {
			Glyph * glyph = getCharGlyph(text[i], true);
			if (glyph is null)
				continue;
			if ( glyph.blackBoxX && glyph.blackBoxY ) {
                int x0 = x + xx + glyph.originX;
                int y0 = y + bl - glyph.originY;
                if (x0 > buf.width)
                    break; // outside right bound
                Rect rc = Rect(x0, y0, x0 + glyph.blackBoxX, y0 + glyph.blackBoxY);
                if (buf.applyClipping(rc))
				    buf.drawGlyph( x0,
                               y0,
                              glyph,
                              color);
			}
            xx += glyph.width;
		}
	}

	override int measureText(const dchar[] text, ref int[] widths, int maxWidth) {
		if (text.length == 0)
			return 0;
		const dchar * pstr = text.ptr;
		uint len = cast(uint)text.length;
        int x = 0;
        int charsMeasured = 0;
		for (int i = 0; i < len; i++) {
			Glyph * glyph = getCharGlyph(text[i], true); // TODO: what is better
			if (glyph is null) {
                // if no glyph, use previous width - treat as zero width
                widths[i] = i > 0 ? widths[i-1] : 0;
				continue;
            }
            int w = x + glyph.width; // using advance
            int w2 = x + glyph.originX + glyph.blackBoxX; // using black box
            if (w < w2) // choose bigger value
                w = w2;
            widths[i] = w;
            x += glyph.width;
            charsMeasured = i + 1;
            if (x > maxWidth)
                break;
        }
		return charsMeasured;
	}

	bool create() {
        if (!isNull())
            clear();
        foreach (string filename; _fontItem.filenames) {
            FreeTypeFontFile file = new FreeTypeFontFile(_fontItem.library, filename);
            if (file.open(_size, 0)) {
                _files ~= file;
            }
        }
		return _files.length > 0;
	}

	// clear usage flags for all entries
	override void checkpoint() {
		_glyphCache.checkpoint();
	}

	// removes entries not used after last call of checkpoint() or cleanup()
	override void cleanup() {
		_glyphCache.cleanup();
	}

    @property override int size() { return _size; }
    @property override int height() { return _files.length > 0 ? _files[0].height : _size; }
    @property override int weight() { return _fontItem.def.weight; }
    @property override int baseline() { return _files.length > 0 ? _files[0].baseline : 0; }
    @property override bool italic() { return _fontItem.def.italic; }
    @property override string face() { return _fontItem.def.face; }
    @property override FontFamily family() { return _fontItem.def.family; }
    @property override bool isNull() { return _files.length == 0; }
}


/// FreeType based font manager.
class FreeTypeFontManager : FontManager {

    private FT_Library    _library;
    private FontFileItem[] _fontFiles;

    private FontFileItem findFileItem(ref FontDef def) {
        foreach(FontFileItem item; _fontFiles)
            if (item.def == def)
                return item;
        return null;
    }

    private FontFileItem findBestMatch(int weight, bool italic, FontFamily family, string face) {
        FontFileItem best = null;
        int bestScore = 0;
        foreach(FontFileItem item; _fontFiles) {
            int score = 0;
            if (face is null || face.equal(item.def.face))
                score += 200; // face match
            if (family == item.def.family)
                score += 100; // family match
            if (italic == item.def.italic)
                score += 50; // italic match
            int weightDiff = myabs(weight - item.def.weight);
            score += 30 - weightDiff / 30; // weight match
            if (score > bestScore) {
                bestScore = score;
                best = item;
            }
        }
        return best;
    }

	private FontList _activeFonts;

    private static FontRef _nullFontRef;

    this() {
        // load dynaic library
        DerelictFT.load();
        // init library
        int error = FT_Init_FreeType(&_library);
        if (error) {
            Log.e("Cannot init freetype library, error=", error);
            throw new Exception("Cannot init freetype library");
        }
    }
    ~this() {
		Log.d("FreeTypeFontManager ~this() active fonts: ", _activeFonts.length);
		_activeFonts.clear();
		foreach(ref FontFileItem item; _fontFiles) {
			destroy(item);
			item = null;
		}
		_fontFiles.length = 0;
        // uninit library
        if (_library)
            FT_Done_FreeType(_library);
    }

    /// get font instance with specified parameters
    override ref FontRef getFont(int size, int weight, bool italic, FontFamily family, string face) {
        FontFileItem f = findBestMatch(weight, italic, family, face);
        if (f is null)
            return _nullFontRef;
        return f.get(size);
    }

	/// clear usage flags for all entries
	override void checkpoint() {
    }

	/// removes entries not used after last call of checkpoint() or cleanup()
	override void cleanup() {
    }

    /// register freetype font by filename - optinally font properties can be passed if known (e.g. from libfontconfig).
    bool registerFont(string filename, FontFamily family = FontFamily.SansSerif, string face = null, bool italic = false, int weight = 0) {
        if (_library is null)
            return false;
        Log.d("FreeTypeFontManager.registerFont ", filename, " ", family, " ", face, " italic=", italic, " weight=", weight);
        if (!exists(filename) || !isFile(filename))
            return false;

        FreeTypeFontFile font = new FreeTypeFontFile(_library, filename);
        if (!font.open(24)) {
            Log.e("Failed to open font ", filename);
            destroy(font);
            return false;
        }
        
        if (face == null || weight == 0) {
            // properties are not set by caller
            // get properties from loaded font
            face = font.face;
            italic = font.italic;
            weight = font.weight;
            Log.d("Using properties from font file: face=", face, " weight=", weight, " italic=", italic);
        }

        FontDef def = FontDef(family, face, italic, weight);
        FontFileItem item = findFileItem(def);
        if (item is null) {
            item = new FontFileItem(_library, def);
            _fontFiles ~= item;
        }
        item.addFile(filename);

        // registered
        return true;
    }

}

private int myabs(int n) { return n >= 0 ? n : -n; }

module dlangui.graphics.fonts;
public import dlangui.graphics.drawbuf;
public import dlangui.core.types;
public import dlangui.core.logger;
import std.algorithm;

/// font family
enum FontFamily : ubyte {
    Unspecified,
    SansSerif,
    Serif,
	Fantasy,
	Cursive,
    MonoSpace
}

/// useful font weight constants
enum FontWeight : int {
    Normal = 400,
    Bold = 800
}

const dchar UNICODE_SOFT_HYPHEN_CODE = 0x00ad;
const dchar UNICODE_ZERO_WIDTH_SPACE = 0x200b;
const dchar UNICODE_NO_BREAK_SPACE = 0x00a0;
const dchar UNICODE_HYPHEN = 0x2010;
const dchar UNICODE_NB_HYPHEN = 0x2011;

version (USE_OPENGL) {
    private __gshared void function(uint id) _glyphDestroyCallback;
    /// get glyph destroy callback (to cleanup OpenGL caches)
    @property void function(uint id) glyphDestroyCallback() { return _glyphDestroyCallback; }
    /// set glyph destroy callback (to cleanup OpenGL caches)
    @property void glyphDestroyCallback(void function(uint id) callback) { _glyphDestroyCallback = callback; }

    private __gshared uint _nextGlyphId;
    uint nextGlyphId() { return _nextGlyphId++; }
}

/// font glyph cache
struct GlyphCache
{
	Glyph[ushort] _map;
	Glyph[0x10000] _array;

	// find glyph in cache
	Glyph * find(ushort glyphIndex) {
        if (_array[glyphIndex].glyphIndex)
            return &_array[glyphIndex];
        return null;
		
        //Glyph * res = (glyphIndex in _map);
        //if (res !is null)
        //    res.lastUsage = 1;
        //return res;
	}

	/// put glyph to cache
	Glyph * put(ushort glyphIndex, Glyph * glyph) {
        _array[glyphIndex] = *glyph;
        return &_array[glyphIndex];

        //_map[glyphIndex] = *glyph;
        //Glyph * res = glyphIndex in _map;
        //res.lastUsage = 1;
        //return res;
	}

	// clear usage flags for all entries
	void checkpoint() {
		foreach(ref Glyph item; _map) {
			item.lastUsage = 0;
		}
	}

	/// removes entries not used after last call of checkpoint() or cleanup()
	void cleanup() {
		uint dst = 0;
        // notify about destroyed glyphs
        version (USE_OPENGL) {
            if (_glyphDestroyCallback !is null)
				foreach(ref Glyph item; _map) {
					if (item.lastUsage == 0)
                        _glyphDestroyCallback(item.id);
				}
        }
		ushort[] forDelete;
		foreach(ref Glyph item; _map)
			if (item.lastUsage == 0)
				forDelete ~= item.glyphIndex;
		foreach(ushort index; forDelete)
			_map.remove(index);
	}

	/// removes all entries
	void clear() {
        version (USE_OPENGL) {
            if (_glyphDestroyCallback !is null)
				foreach(ref Glyph item; _map) {
					if (item.lastUsage == 0)
                        _glyphDestroyCallback(item.id);
				}
        }
		_map.clear();
	}
	~this() {
		clear();
	}
}

/// Font object
class Font : RefCountedObject {
    abstract @property int size();
    abstract @property int height();
    abstract @property int weight();
    abstract @property int baseline();
    abstract @property bool italic();
    abstract @property string face();
    abstract @property FontFamily family();
    abstract @property bool isNull();
	// measure text string, return accumulated widths[] (distance to end of n-th character), returns number of measured chars.
	abstract int measureText(const dchar[] text, ref int[] widths, int maxWidth);
    private int[] _textSizeBuffer; // to avoid GC
	// measure text string as single line, returns width and height
	Point textSize(const dchar[] text, int maxWidth = 3000) {
        if (_textSizeBuffer.length < text.length + 1)
            _textSizeBuffer.length = text.length + 1;
        //int[] widths = new int[text.length + 1];
        int charsMeasured = measureText(text, _textSizeBuffer, maxWidth);
        if (charsMeasured < 1)
            return Point(0,0);
        return Point(_textSizeBuffer[charsMeasured - 1], height);
    }
	/// draw text string to buffer
	abstract void drawText(DrawBuf buf, int x, int y, const dchar[] text, uint color);
	/// get character glyph information
	abstract Glyph * getCharGlyph(dchar ch, bool withImage = true);

	/// clear usage flags for all entries
	abstract void checkpoint();
	/// removes entries not used after last call of checkpoint() or cleanup()
	abstract void cleanup();

    void clear() {}

    ~this() { clear(); }
}
alias FontRef = Ref!Font;

/// font instance collection - utility class, for font manager implementations
struct FontList {
	FontRef[] _list;
	uint _len;
	~this() {
		clear();
	}
	
	@property uint length() {
		return _len;
	}
	
	void clear() {
		for (uint i = 0; i < _len; i++) {
			_list[i].clear();
			_list[i] = null;
		}
		_len = 0;
	}
	// returns item by index
	ref FontRef get(int index) {
		return _list[index];
	}
	// find by a set of parameters - returns index of found item, -1 if not found
	int find(int size, int weight, bool italic, FontFamily family, string face) {
		for (int i = 0; i < _len; i++) {
			Font item = _list[i].get;
			if (item.family != family)
				continue;
			if (item.size != size)
				continue;
			if (item.italic != italic || item.weight != weight)
				continue;
			if (!equal(item.face, face))
				continue;
			return i;
		}
		return -1;
	}
	// find by size only - returns index of found item, -1 if not found
	int find(int size) {
		for (int i = 0; i < _len; i++) {
			Font item = _list[i].get;
			if (item.size != size)
				continue;
			return i;
		}
		return -1;
	}
	ref FontRef add(Font item) {
		Log.d("FontList.add() enter");
		if (_len >= _list.length) {
			_list.length = _len < 16 ? 16 : _list.length * 2;
		}
		_list[_len++] = item;
		Log.d("FontList.add() exit");
		return _list[_len - 1];
	}
	// remove unused items - with reference == 1
	void cleanup() {
		for (int i = 0; i < _len; i++)
			if (_list[i].refCount <= 1)
				_list[i].clear();
		int dst = 0;
		for (int i = 0; i < _len; i++) {
			if (!_list[i].isNull)
				if (i != dst)
					_list[dst++] = _list[i];
		}
		_len = dst;
		for (int i = 0; i < _len; i++)
			_list[i].cleanup();
	}
	void checkpoint() {
		for (int i = 0; i < _len; i++)
			_list[i].checkpoint();
	}
}


/// Access points to fonts.
class FontManager {
    protected static __gshared FontManager _instance;

    /// sets new font manager singleton instance
    static @property void instance(FontManager manager) {
		if (_instance !is null) {
			destroy(_instance);
            _instance = null;
        }
        _instance = manager;
    }

    /// returns font manager singleton instance
    static @property FontManager instance() {
        return _instance;
    }

    /// get font instance best matched specified parameters
    abstract ref FontRef getFont(int size, int weight, bool italic, FontFamily family, string face);

	/// clear usage flags for all entries -- for cleanup of unused fonts
	abstract void checkpoint();

	/// removes entries not used after last call of checkpoint() or cleanup()
	abstract void cleanup();

	~this() {
		Log.d("Destroying font manager");
	}
}

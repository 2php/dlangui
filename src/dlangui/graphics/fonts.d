module dlangui.graphics.fonts;
public import dlangui.graphics.drawbuf;
public import dlangui.core.types;
public import dlangui.core.logger;
import std.algorithm;

enum FontFamily : ubyte {
    SansSerif,
    Serif,
	Fantasy,
	Cursive,
    MonoSpace
}

enum FontWeight : int {
    Normal = 400,
    Bold = 800
}

struct Glyph
{
    ubyte   blackBoxX;   ///< 0: width of glyph
    ubyte   blackBoxY;   ///< 1: height of glyph black box
    byte    originX;     ///< 2: X origin for glyph
    byte    originY;     ///< 3: Y origin for glyph
    ushort  glyphIndex;  ///< 4: bytes in glyph array
    ubyte   width;       ///< 6: full width of glyph
	ubyte   lastUsage;
    ubyte[] glyph;    ///< 7: glyph data, arbitrary size
}

struct GlyphCache
{
	Glyph[] _data;
	uint _len;

	// find glyph in cache
	Glyph * find(ushort glyphIndex) {
		for (uint i = 0; i < _len; i++) {
			Glyph * item = &_data[i];
			if (item.glyphIndex == glyphIndex) {
				item.lastUsage = 1;
				return item;
			}
		}
		return null;
	}

	Glyph * put(ushort glyphIndex, Glyph * glyph) {
		if (_len >= _data.length) {
			uint newsize = (_len < 32) ? 32 : _len * 2;
			_data.length = newsize;
		}
		_data[_len++] = *glyph;
		Glyph * res = &_data[_len - 1];
		res.lastUsage = 1;
		return res;
	}

	// clear usage flags for all entries
	void checkpoint() {
		for (uint src = 0; src < _len; src++) {
			_data[src].lastUsage = 0;
		}
	}

	// removes entries not used after last call of checkpoint() or cleanup()
	void cleanup() {
		uint dst = 0;
		for (uint src = 0; src < _len; src++) {
			if (_data[src].lastUsage != 0) {
				_data[src].lastUsage = 0;
				if (src != dst) {
					_data[dst++] = _data[src];
				}
			}
		}
		_len = dst;
	}

	// removes all entries
	void clear() {
		_data = null;
		_len = 0;
	}
	~this() {
		clear();
	}
}

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
	// measure text string as single line, returns width and height
	Point textSize(const dchar[] text, int maxWidth = 3000) {
        int[] widths = new int[text.length + 1];
        int charsMeasured = measureText(text, widths, maxWidth);
        if (charsMeasured < 1)
            return Point(0,0);
        return Point(widths[charsMeasured - 1], height);
    }
	// draw text string to buffer
	abstract void drawText(DrawBuf buf, int x, int y, const dchar[] text, uint color);
	abstract Glyph * getCharGlyph(dchar ch);

	// clear usage flags for all entries
	abstract void checkpoint();
	// removes entries not used after last call of checkpoint() or cleanup()
	abstract void cleanup();

    void clear() {}

    ~this() { clear(); }
}
alias FontRef = Ref!Font;

struct FontList {
	FontRef[] _list;
	uint _len;
	~this() {
		for (uint i = 0; i < _len; i++) {
			_list[i].clear();
		}
	}
	// returns item by index
	ref FontRef get(int index) {
		return _list[index];
	}
	// returns index of found item, -1 if not found
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

class FontManager {
    static __gshared FontManager _instance;
    static @property void instance(FontManager manager) {
        _instance = manager;
    }
    static @property FontManager instance() {
        return _instance;
    }

    abstract ref FontRef getFont(int size, int weight, bool italic, FontFamily family, string face);

	// clear usage flags for all entries
	abstract void checkpoint();

	// removes entries not used after last call of checkpoint() or cleanup()
	abstract void cleanup();

	~this() {}
}

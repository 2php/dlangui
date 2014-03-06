module dlangui.core.types;

struct Point {
    int x;
    int y;
    this(int x0, int y0) {
        x = x0;
        y = y0;
    }
}

struct Rect {
    int left;
    int top;
    int right;
    int bottom;
    @property int width() { return right - left; }
    @property int height() { return bottom - top; }
    this(int x0, int y0, int x1, int y1) {
        left = x0;
        top = y0;
        right = x1;
        bottom = y1;
    }
    @property bool empty() {
        return right <= left || bottom <= top;
    }
    bool intersect(Rect rc) {
        if (left < rc.left)
            left = rc.left;
        if (top < rc.top)
            top = rc.top;
        if (right > rc.right)
            right = rc.right;
        if (bottom > rc.bottom)
            bottom = rc.bottom;
        return right > left && bottom > top;
    }
}

class RefCountedObject {
    protected int _refCount;
    @property int refCount() { return _refCount; }
    void addRef() { 
		_refCount++; 
	}
    void releaseRef() { 
		if (--_refCount == 0) 
			destroy(this); 
	}
    ~this() {}
}

struct Ref(T) { // if (T is RefCountedObject)
    private T _data;
    alias get this;
    @property bool isNull() { return _data is null; }
    @property int refCount() { return _data !is null ? _data.refCount : 0; }
    this(T data) {
        _data = data;
        if (_data !is null)
            _data.addRef();
    }
	this(this) {
		if (_data !is null)
            _data.addRef();
	}
    ref Ref opAssign(ref Ref data) {
        if (data._data == _data)
            return this;
        if (_data !is null)
            _data.releaseRef();
        _data = data._data;
        if (_data !is null)
            _data.addRef();
		return this;
    }
    ref Ref opAssign(Ref data) {
        if (data._data == _data)
            return this;
        if (_data !is null)
            _data.releaseRef();
        _data = data._data;
        if (_data !is null)
            _data.addRef();
		return this;
    }
    ref Ref opAssign(T data) {
        if (data == _data)
            return this;
        if (_data !is null)
            _data.releaseRef();
        _data = data;
        if (_data !is null)
            _data.addRef();
		return this;
    }
    void clear() { 
        if (_data !is null) {
            _data.releaseRef();
            _data = null;
        }
    }
	@property T get() {
		return _data;
	}
	@property const(T) get() const {
		return _data;
	}
    ~this() {
        if (_data !is null)
            _data.releaseRef();
    }
}


// some utility functions
string fromStringz(const(char[]) s) {
	int i = 0;
	while(s[i])
		i++;
	return cast(string)(s[0..i].dup);
}

string fromStringz(const(char*) s) {
	int i = 0;
	while(s[i])
		i++;
	return cast(string)(s[0..i].dup);
}

wstring fromWStringz(const(wchar[]) s) {
	int i = 0;
	while(s[i])
		i++;
	return cast(wstring)(s[0..i].dup);
}


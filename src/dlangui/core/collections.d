module dlangui.core.collections;

import std.algorithm;

/// array based collection of items
/// retains item order when during add/remove operations
struct Collection(T) {
    private T[] _items;
    private size_t _len;
    /// returns number of items in collection
    @property size_t length() { return _len; }
    /// returns currently allocated capacity (may be more than length)
    @property size_t size() { return _items.length; }
    /// change capacity (e.g. to reserve big space to avoid multiple reallocations)
    @property void size(size_t newSize) {
        if (_len > newSize)
            length = newSize; // shrink
        _items.length = newSize; 
    }
    /// returns number of items in collection
    @property void length(size_t newSize) { 
        if (newSize < _len) {
            // shrink
            static if (is(T == class) || is(T == struct)) {
                // clear items
                for (size_t i = newSize; i < _len; i++)
                    _items[i] = T.init;
            }
        } else if (newSize > _len) {
            // expand
            if (_items.length < newSize)
                _items.length = newSize;
        }
        _len = newSize;
    }
    /// access item by index
    ref T opIndex(size_t index) {
        assert(index < _len);
        return _items[index];
    }
    /// insert new item in specified position
    void add(T item, size_t index = size_t.max) {
        if (index > _len)
            index = _len;
        if (_items.length >= _len) {
            if (_items.length < 4)
                _items.length = 4;
            else
                _items.length = _items.length * 2;
        }
        if (index < _len) {
            for (size_t i = _len; i > index; i--)
                _items[i] = _items[i - 1];
        }
        _items[index] = item;
        _len++;
    }
    /// support for appending (~=, +=) and removing by value (-=)
    ref Collection opOpAssign(string op)(T item) {
        static if (op.equal("~") || op.equal("+")) {
            // append item to end of collection
            add(item);
            return this;
        } else if (op.equal("-")) {
            // remove item from collection, if present
            removeValue(item);
            return this;
        } else {
            assert(false, "not supported opOpAssign " ~ op);
        }
    }
    /// returns index of first occurence of item, size_t.max if not found
    size_t indexOf(T item) {
        for (size_t i = 0; i < _len; i++)
            if (_items[i] == item)
                return i;
        return size_t.max;
    }
    /// remove single item, returning removed item
    T remove(size_t index) {
        assert(index < _len);
        T result = _items[index];
        for (size_t i = index; i + 1 < _len; i++)
            _items[i] = _items[i + 1];
        _items[_len] = T.init;
        _len--;
        return result;
    }
    /// remove single item by value - if present in collection, returning true if item was found and removed
    bool removeValue(T value) {
        size_t index = indexOf(value);
        if (index == size_t.max)
            return false;
        remove(index);
        return true;
    }
    /// support of foreach with reference
    int opApply(int delegate(ref T param) op) {
        int result = 0;
        for (size_t i = 0; i < _len; i++) {
            result = op(_items[i]);
            if (result)
                break;
        }
        return result;
    }
    /// remove all items
    void clear() {
        static if (is(T == class) || is(T == struct)) {
            /// clear references
            for(size_t i = 0; i < _len; i++)
                _items[i] = T.init;
        }
        _len = 0;
        _items = null;
    }
    ~this() {
        clear();
    }
}


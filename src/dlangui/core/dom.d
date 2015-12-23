module dlangui.core.dom;

import dlangui.core.collections;

import std.traits;
import std.conv : to;
import std.string : startsWith, endsWith;
import std.array : empty;
import std.algorithm : equal;

// Namespace, element tag and attribute names are stored as numeric ids for better performance and lesser memory consumption.

/// id type for interning namespaces
alias ns_id = ushort;
/// id type for interning element names
alias elem_id = uint;
/// id type for interning attribute names
alias attr_id = ushort;


/// Base class for DOM nodes
class Node {
private:
    Node _parent;
    Document _document;
public:
    /// returns parent node
    @property Node parent() { return _parent; }
    /// returns document node
    @property Document document() { return _document; }

    /// return element tag id
    @property elem_id id() { return 0; }
    /// return element namespace id
    @property ns_id nsid() { return 0; }
    /// return element tag name
    @property string name() { return document.tagName(id); }
    /// return element namespace name
    @property string nsname() { return document.nsName(nsid); }

    // node properties

    /// returns true if node is text
    @property bool isText() { return false; }
    /// returns true if node is element
    @property bool isElement() { return false; }
    /// returns true if node has child nodes
    @property bool hasChildren() { return false; }

    // attributes

    /// returns attribute count
    @property int attrCount() { return 0; }

    // child nodes

    /// returns child node count
    @property int childCount() { return 0; }
    /// returns child node by index
    @property Node child(int index) { return null; }
    /// returns first child node
    @property Node firstChild() { return null; }
    /// returns last child node
    @property Node lastChild() { return null; }

    /// find child node, return its index if found, -1 if not found or not child of this node
    int childIndex(Node child) { return -1; }
    /// return node index in parent's child node collection, -1 if not found
    @property int index() { return _parent ? _parent.childIndex(this) : -1; }

    /// append text child
    Node appendText(dstring s, int index = -1) { assert(false); }
    /// append element child - by namespace and tag names
    Node appendElement(string ns, string tag, int index = -1) { assert(false); }
    /// append element child - by namespace and tag ids
    Node appendElement(ns_id ns, elem_id tag, int index = -1) { assert(false); }

    /// node text
    @property dstring text() { return null; }
    /// ditto
    @property void text(dstring s) { }


}

/// Text node
class Text : Node {
private:
    dstring _text;
    this(Document doc, dstring text = null) {
        _document = doc;
        _text = text;
    }
public:
    /// node text
    override @property dstring text() { return _text; }
    /// ditto
    override @property void text(dstring s) { _text = s; }
}

/// Element node
class Element : Node {
private:
    Collection!Node _children;
    elem_id _id; // element tag id
    ns_id _ns; // element namespace id

    this(Document doc, ns_id ns, elem_id id) {
        _document = doc;
        _ns = ns;
        _id = id;
    }
public:

    /// return element tag id
    override @property elem_id id() { return _id; }
    /// return element namespace id
    override @property ns_id nsid() { return _ns; }

    // child nodes

    /// returns child node count
    override @property int childCount() { return cast(int)_children.length; }
    /// returns child node by index
    override @property Node child(int index) { return index >= 0 && index < _children.length ? _children[index] : null; }
    /// returns first child node
    override @property Node firstChild() { return _children.length > 0 ? _children[0] : null; }
    /// returns last child node
    override @property Node lastChild() { return _children.length > 0 ? _children[_children.length - 1] : null; }
    /// find child node, return its index if found, -1 if not found or not child of this node
    override int childIndex(Node child) { 
        for (int i = 0; i < _children.length; i++)
            if (child is _children[i])
                return i;
        return -1;
    }

    /// append text child
    override Node appendText(dstring s, int index = -1) {
        Node item = document.createText(s);
        _children.add(item, index >= 0 ? index : size_t.max);
        return item;
    }
    /// append element child - by namespace and tag names
    override Node appendElement(string ns, string tag, int index = -1) { 
        Node item = document.createElement(ns, tag);
        _children.add(item, index >= 0 ? index : size_t.max);
        return item;
    }
    /// append element child - by namespace and tag ids
    override Node appendElement(ns_id ns, elem_id tag, int index = -1) { 
        Node item = document.createElement(ns, tag);
        _children.add(item, index >= 0 ? index : size_t.max);
        return item;
    }
}

/// Document node
class Document : Element {
public:
    this() {
        super(null, 0, 0);
        _elemIds.init!Tag();
        _attrIds.init!Attr();
        _nsIds.init!Ns();
        _document = this;
    }
    /// create text node
    Text createText(dstring text) {
        return new Text(this, text);
    }
    /// create element node by namespace and tag ids
    Element createElement(ns_id ns, elem_id tag) {
        return new Element(this, ns, tag);
    }
    /// create element node by namespace and tag names
    Element createElement(string ns, string tag) {
        return new Element(this, internNs(ns), internTag(tag));
    }

    // Ids

    /// return name for element tag id
    string tagName(elem_id id) {
        return _elemIds[id];
    }
    /// return name for namespace id
    string nsName(ns_id id) {
        return _nsIds[id];
    }
    /// return name for attribute id
    string attrName(ns_id id) {
        return _attrIds[id];
    }
    /// get id for element tag name
    elem_id internTag(string s) {
        if (s.empty)
            return 0;
        return _elemIds.intern(s);
    }
    /// get id for namespace name
    ns_id internNs(string s) {
        if (s.empty)
            return 0;
        return _nsIds.intern(s);
    }
    /// get id for namespace name
    attr_id internAttr(string s) {
        if (s.empty)
            return 0;
        return _attrIds.intern(s);
    }
private:
    IdentMap!(elem_id) _elemIds;
    IdentMap!(attr_id) _attrIds;
    IdentMap!(ns_id) _nsIds;
}



/// remove trailing _ from string, e.g. "body_" -> "body"
private string removeTrailingUnderscore(string s) {
    if (s.endsWith("_"))
        return s[0..$-1];
    return s;
}

/// String identifier to Id map - for interning strings
struct IdentMap(ident_t) {
    /// initialize with elements of enum
    void init(E)() if (is(E == enum)) {
        foreach(member; EnumMembers!E) {
            static if (member.to!int) {
                //pragma(msg, "interning string '" ~ removeTrailingUnderscore(member.to!string) ~ "' for " ~ E.stringof);
                intern(removeTrailingUnderscore(member.to!string), member);
            }
        }
    }
    /// intern string - return ID assigned for it
    ident_t intern(string s, ident_t id = 0) {
        if (auto p = s in _stringToId)
            return *p;
        ident_t res;
        if (id > 0) {
            if (_nextId <= id)
                _nextId = cast(ident_t)(id + 1);
            res = id;
        } else {
           res = _nextId++;
        }
        _idToString[res] = s;
        _stringToId[s] = res;
        return res;
    }
    /// lookup id for string, return 0 if string is not found
    ident_t opIndex(string s) {
        if (s.empty)
            return 0;
        if (auto p = s in _stringToId)
            return *p;
        return 0;
    }
    /// lookup name for id, return null if not found
    string opIndex(ident_t id) {
        if (!id)
            return null;
        if (auto p = id in _idToString)
            return *p;
        return null;
    }
private:
    string[ident_t] _idToString;
    ident_t[string] _stringToId;
    ident_t _nextId = 1;
}

/// standard tags
enum Tag {
    NONE,
    body_,
    pre,
    div,
    span
}

/// standard attributes
enum Attr {
    NONE,
    id,
    class_,
    style
}

/// standard namespaces
enum Ns {
    NONE,
    xmlns,
    xs,
    xlink,
    l,
    xsi
}

unittest {
    import std.algorithm : equal;
    //import std.stdio;
    IdentMap!(elem_id) map;
    map.init!Tag();
    //writeln("running DOM unit test");
    assert(map["pre"] == Tag.pre);
    assert(map["body"] == Tag.body_);
    assert(map[Tag.div].equal("div"));

    Document doc = new Document();
    auto body_ = doc.appendElement(null, "body");
    assert(body_.id == Tag.body_);
    assert(body_.name.equal("body"));
    auto div = body_.appendElement(null, "div");
    assert(body_.childCount == 1);
    assert(div.id == Tag.body_);
    assert(div.name.equal("div"));
    div.appendText("Some text"d);
    assert(div.childCount == 1);
    assert(div.child(0).text.equal("Some text"d));

    destroy(doc);
}

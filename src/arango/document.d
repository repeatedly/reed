// Written in the D programming language.

module arango.document;

import std.conv     : to, text;
import std.json     : JSONValue;
import std.typecons : Tuple;

import arango.util;

version(unittest) import std.exception;

package
{
    immutable DocumentAPIPath = "document";
}

struct Document(T)
{
    DocumentHandle handle;
    T content;

    alias content this;
}

struct DocumentHandle
{
    static immutable Separator = '/';

    string _id;
    ulong _rev;

    @trusted
    {
        static private Tuple!(ulong, ulong) parseId(string id)
        {
            import std.string;

            const pos = indexOf(id, Separator);
            if (pos == -1)
                throw new Exception("document-identifier must have '/'");

            Tuple!(ulong, ulong) result;
            result[0] = id[0..pos].to!ulong();
            result[1] = id[pos + 1..$].to!ulong();
            return result;
        }

        this(string id, ulong rev)
        {
            parseId(id);

            _rev = rev;
            _id = id;
        }

        this(string id)
        {
            _rev = parseId(id)[1];
            _id = id;
        }

        this(ulong collectionId, ulong rev)
        {
            _rev = rev;
            _id = text(collectionId, Separator, rev);
        }
    }

    @property @safe nothrow
    {
        string id() const
        {
            return _id;
        }

        void id(string newId)
        {
            _id = newId;
        }

        ulong revision() const
        {
            return _rev;
        }

        void revision(ulong newRevision)
        {
            _rev = newRevision;
        }
    }

    @safe
    bool opEquals(ref const DocumentHandle other)
    {
        return _id == other._id && _rev == other._rev;
    }
}

unittest
{
    {
        assert(DocumentHandle("123/456") == DocumentHandle(123, 456));
        assert(DocumentHandle("123/456", 456) == DocumentHandle(123, 456));

        auto handle = DocumentHandle("123/456", 789);
        assert(handle.id == "123/456");
        assert(handle.revision == 789);
    }
    {
        assertThrown(DocumentHandle(""));
        assertThrown(DocumentHandle("handa"));
        assertThrown(DocumentHandle("handa/shinobu"));
        assertThrown(DocumentHandle("handa/456"));
        assertThrown(DocumentHandle("123/shinobu"));
    }
}

@safe
Document!T toDocument(T)(ref JSONValue value)
{
    auto newHandle = extractDocumentHandle(value);
    static if (is(T : JSONValue))
    {
        return Document!T(newHandle, value);
    }
    else
    {
        return Document!T(newHandle, fromJSONValue!T(value));
    }
}

package:

@safe
DocumentHandle extractDocumentHandle(ref JSONValue value)
{
    // TODO: check id and rev if needed

    auto id = value.object["_id"].str;
    auto rev = value.object["_rev"].integer;

    value.object.remove("_id");
    value.object.remove("_rev");

    return DocumentHandle(id, rev);
}

unittest
{
    JSONValue value = std.json.parseJSON(`{"_id": "123/456", "_rev": 789}`);
    assert(extractDocumentHandle(value) == DocumentHandle("123/456", 789));
}

@trusted
Document!(T)[] toDocuments(T)(ref JSONValue response)
{
    import std.algorithm : map;
    return array(map!(toDocument!T)(response.array));
}

@safe
string buildDocumentPath(ref const DocumentHandle handle)
{
    return buildUriPath(DocumentAPIPath, handle.id);
}

unittest
{
    assert(buildDocumentPath(DocumentHandle("123/456")) == "document/123/456");

    assertThrown(buildDocumentPath(DocumentHandle("123")));
    assertThrown(buildDocumentPath(DocumentHandle("123/456/789")));
}

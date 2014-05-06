// Written in the D programming language.

module reed.document;

import std.conv     : to, text;
import std.json     : JSONValue;
import std.typecons : Tuple;

import reed.database;
import reed.util;

version(unittest) import std.exception;

package
{
    immutable DocumentAPIPath = buildUriPath(Database.APIPrefix, "document");
}

/**
 * See: http://www.arangodb.org/manuals/current/RestDocument.html#RestDocumentIntro
 */
struct Document(T)
{
    DocumentHandle handle;
    T content;
    alias content this;

    /*
     * Why this opEquals needed?
     */
    @safe nothrow const
    {
        bool opEquals(V)(const V other)
        {
            return opEquals!T(other);
        }

        bool opEquals(V)(ref const V other)
        {
            static if (is(V : Document))
                return handle == other.handle && content == other.content;
            else
                return content == other;
        }
    }
}

struct DocumentHandle
{
    static immutable dchar Separator = '/';

    // This naming conversion for toJSONValue. ArangoDB's document handle has '_id' and '_rev' fields.
    string _id;
    string _rev;
    string _key;

    @trusted
    static private Tuple!(string, string) parseId(string id)
    {
        import std.string;
        import std.stdio;

        const pos = indexOf(id, Separator);
        if (pos == -1)
            throw new Exception("document-identifier must have '/'");

        Tuple!(string, string) result;
        result[0] = id[0..pos];
        result[1] = id[pos + 1..$];
        return result;
    }

    @trusted
    static DocumentHandle fromCollectionId(string collectionId, string rev)
    {
        return DocumentHandle(text(collectionId, Separator, rev), rev);
    }

    @safe
    {
        this(string id, string rev)
        {
            _id = id;
            _rev = rev;
            _key = parseId(id)[1]; // “_key” will automatically become part of a document’s “_id” value.
        }

        this(string id)
        {
            _id = id;
            _rev = _key = parseId(id)[1];
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

        string key() const
        {
            return _key;
        }

        void key(string newKey)
        {
            _key = newKey;
        }

        string revision() const
        {
            return _rev;
        }

        void revision(string newRevision)
        {
            _rev = newRevision;
        }
    }

    @safe nothrow const
    {
        bool opEquals(const DocumentHandle other)
        {
            return opEquals(other);
        }

        bool opEquals(ref const DocumentHandle other)
        {
            return _id == other._id && _rev == other._rev;
        }
    }
}

unittest
{
    {
        assert(DocumentHandle("123/456") == DocumentHandle.fromCollectionId("123", "456"));
        assert(DocumentHandle("123/456", "456") == DocumentHandle.fromCollectionId("123", "456"));

        auto handle = DocumentHandle("123/456", "789");
        assert(handle.id == "123/456");
        assert(handle.key == "456");
        assert(handle.revision == "789");
    }
    { // allow name based _id since 1.2
        auto handle = DocumentHandle("handa/shinobu");
        assert(handle.id == "handa/shinobu");
        assert(handle.key == "shinobu");
        assert(handle.revision == "shinobu");
    }
    {
        assertThrown(DocumentHandle(""));
        assertThrown(DocumentHandle("handa"));
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

@trusted
DocumentHandle extractDocumentHandle(ref JSONValue value)
{
    // TODO: check id and rev if needed

    auto id = value.object["_id"].str;
    auto rev = value.object["_rev"].str;

    value.object.remove("_id");
    value.object.remove("_rev");
    value.object.remove("_key");

    return DocumentHandle(id, rev);
}

@trusted
void insertKey(ref JSONValue value, in string key)
{
    value.object["_key"] = key.toJSONValue();
}

unittest
{
    JSONValue value = std.json.parseJSON(`{"_id": "123/456", "_rev": "789"}`);
    assert(extractDocumentHandle(value) == DocumentHandle("123/456", "789"));
}

@trusted
Document!(T)[] toDocuments(T)(ref JSONValue response)
{
    import std.algorithm : map;
    return array(map!(toDocument!T)(response.array));
}

@safe
{
    string buildDocumentPath(const DocumentHandle handle)
    {
        return buildUriPath(DocumentAPIPath, handle.id);
    }

    string buildDocumentPath(ref const DocumentHandle handle)
    {
        return buildUriPath(DocumentAPIPath, handle.id);
    }
}

unittest
{
    assert(buildDocumentPath(DocumentHandle("123/456")) == "_api/document/123/456");

    assertThrown(buildDocumentPath(DocumentHandle("123")));
}

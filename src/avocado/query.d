// Written in the D programming language.

module avocado.query;

import std.array    : empty, front, popFront, array;
import std.typecons : Nullable;

import avocado.database;
import avocado.document;
import avocado.util;

package
{
    immutable SimpleQueryAPIPath = buildUriPath(Database.APIPrefix, "simple");
    immutable CursorAPIPath = buildUriPath(Database.APIPrefix, "cursor");
}

struct ByExampleOption
{
    string collection;
    Nullable!long skip;
    Nullable!long limit;
}

alias ByExampleOption AllOption;

private
{
    alias Connection.Method Method;
}

struct Cursor(T)
{
  private:
    bool hasMore_;
    ulong cursorId_;
    Document!(T)[] documents_;

    Database database_;

  public:
    this(Database database, ref JSONValue value)
    {
        parseCursorResult(value);
        database_ = database;
    }

    @property @safe
    {
        nothrow bool empty() const
        {
            return documents_.empty;
        }

        inout(Document!T) front() inout
        {
            return documents_.front;
        }
    }

    void popFront()
    {
        documents_.popFront();

        if (documents_.empty) {
            if (hasMore_)
                fetchDocuments();
        }
    }

  private:
    void fetchDocuments()
    {
        const request = Connection.Request(Method.PUT, buildCursorPath(cursorId_));
        auto response = database_.sendRequest(request);
        parseCursorResult(response);
    }

    void parseCursorResult(ref JSONValue value)
    {
        if ("id" in value.object)
            cursorId_ = value.object["id"].integer;
        documents_ = value.object["result"].toDocuments!T;
        hasMore_ = value.object["hasMore"].type == std.json.JSON_TYPE.TRUE;
    }
}

mixin template SimpleQueryAPIs()
{
    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpSimple.html#HttpSimpleAll
     */
    @trusted
    Cursor!(T) queryAll(T = JSONValue)(ref AllOption option = AllOption())
    {
        option.collection = name_;
        const query = option.toJSONValue();
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("all"), query.toJSON());
        auto response = database_.sendRequest(request);

        return typeof(return)(database_, response);
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/OTWP.html#OTWPSimpleQueriesByExample
     */
    @trusted
    Document!(T)[] queryByExample(T = JSONValue, S)(S example, ref ByExampleOption option = ByExampleOption())
    {
        option.collection = name_;
        auto query = option.toJSONValue();
        query.object["example"] = example.toJSONValue();

        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("by-example"), query.toJSON());
        auto response = database_.sendRequest(request);

        return response.toDocuments!T;
    }

  private:
    @safe
    static string buildSimpleQueryPath(string path) // pure
    {
        return buildUriPath(SimpleQueryAPIPath, path);
    }

    unittest
    {
        assert(buildSimpleQueryPath("by-example") == "_api/simple/by-example");
        assert(buildSimpleQueryPath("near") == "_api/simple/near");
        assert(buildSimpleQueryPath("within") == "_api/simple/within");
    }
}

package:

@safe
string buildCursorPath(ulong id) // pure
{
    return buildUriPath(CursorAPIPath, id);
}

@trusted
Document!(T)[] toDocuments(T)(ref JSONValue response)
{
    import std.algorithm : map;
    return array(map!(toDocument!T)(response.array));
}

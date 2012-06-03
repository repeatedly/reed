// Written in the D programming language.

module arango.query;

import std.array    : empty, front, popFront, array;
import std.typecons : Nullable;

import arango.database;
import arango.document;
import arango.util;

package
{
    immutable SimpleQueryAPIPath = buildUriPath(Database.APIPrefix, "simple");
    immutable CursorAPIPath = buildUriPath(Database.APIPrefix, "cursor");
}

struct ByExampleOption
{
    Nullable!long skip;
    Nullable!long limit;
}

alias ByExampleOption AllOption;

struct CursorOption
{
    Nullable!bool count;
    Nullable!long batchSize;
    //Nullable!(string[string]) bindVars; Manual does not describe an example
}

private
{
    alias Connection.Method Method;
}

struct Cursor(T)
{
  private:
    bool hasMore_;
    long cursorId_;
    Nullable!long count_;
    Document!(T)[] documents_;

    Database database_;

  public:
    this(Database database, ref JSONValue value)
    {
        parseCursorResult(value);
        database_ = database;

        if ("count" in value.object)
            count_ = value.object["count"].integer;
    }

    @property @safe
    {
        long id() const
        {
            return cursorId_;
        }

        long count() const
        in
        {
            assert(count_, "Cannot call count on query without 'count' parameter");
        }
        body
        {
            return count_.get;
        }

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

mixin template QueryAPIs()
{
    /**
     * See_Also: http://www.arangodb.org/manuals/HttpCursor.html#HttpCursorHttp
     */
    @trusted
    Cursor!(T) queryCursor(T = JSONValue)(in string aqlQuery, ref const CursorOption option = CursorOption())
    {
        auto query = option.toJSONValue();
        query.object["query"] = aqlQuery.toJSONValue();
        const request = Connection.Request(Method.POST, CursorAPIPath, query.toJSON());
        auto response = database_.sendRequest(request);

        return typeof(return)(database_, response);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/HttpSimple.html#HttpSimpleAll
     */
    @trusted
    Cursor!(T) queryAll(T = JSONValue)(ref const AllOption option = AllOption())
    {
        auto query = option.toJSONValue();
        query.object["collection"] = name_.toJSONValue();
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("all"), query.toJSON());
        auto response = database_.sendRequest(request);

        return typeof(return)(database_, response);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/OTWP.html#OTWPSimpleQueriesByExample
     */
    @trusted
    Document!(T)[] queryByExample(T = JSONValue, S)(S example, ref const ByExampleOption option = ByExampleOption())
    {
        auto query = option.toJSONValue();
        query.object["collection"] = name_.toJSONValue();
        query.object["example"] = example.toJSONValue();
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("by-example"), query.toJSON());
        auto response = database_.sendRequest(request);

        return response.object["result"].toDocuments!T;
    }

  private:
    @safe
    static string buildSimpleQueryPath(in string path) // pure
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
string buildCursorPath(long id) // pure
{
    return buildUriPath(CursorAPIPath, id);
}

@trusted
Document!(T)[] toDocuments(T)(ref JSONValue response)
{
    import std.algorithm : map;
    return array(map!(toDocument!T)(response.array));
}

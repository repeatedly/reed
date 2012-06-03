// Written in the D programming language.

module arango.query;

import std.array    : empty, front, popFront, array;
import std.typecons : Nullable;

import arango.database;
import arango.document;
import arango.util;

public
{
    import arango.cursor : Cursor;
}

package
{
    immutable SimpleQueryAPIPath = buildUriPath(Database.APIPrefix, "simple");
}

struct ByExampleOption
{
    Nullable!long skip;
    Nullable!long limit;
}

alias ByExampleOption AllOption;

private
{
    alias Connection.Method Method;
}

mixin template SimpleQueryAPIs()
{
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

    /**
     * See_Also: http://www.arangodb.org/manuals/HttpSimple.html#HttpSimpleFirstExample
     */
    @trusted
    Document!(T) queryFirstExample(T = JSONValue, S)(S example)
    {
        static struct Query
        {
            string collection;
            const string[string] example;
        }

        auto query = Query(name_, example).toJSONValue();
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("first-example"), query.toJSON());
        auto response = database_.sendRequest(request);

        return response.object["document"].toDocument!T;
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

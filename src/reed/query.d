// Written in the D programming language.

module reed.query;

import std.array    : empty, front, popFront, array;
import std.typecons : Nullable;

import reed.database;
import reed.document;
import reed.util;

public
{
    import reed.cursor : Cursor;
}

package
{
    immutable SimpleQueryAPIPath = buildUriPath(Database.APIPrefix, "simple");
}

private
{
    alias Connection.Method Method;

    mixin template OptionFields()
    {
        Nullable!long skip;
        Nullable!long limit;
    }
}

/**
 * Optional:
 *  - skip
 *  - limit
 */
struct ByExampleOption
{
    mixin OptionFields;
}

/// ditto
alias ByExampleOption AllOption;

/**
 * Required:
 *  - attribute
 *  - left
 *  - right
 *
 * Optional:
 *  - skip
 *  - limit
 *  - closed
 */
struct RangeOption
{
    string attribute;
    long left;
    long right;
    Nullable!bool closed;
    mixin OptionFields;
}

///
struct FulltextOption
{
    string attribute;
    string query;
    Nullable!string index;
    mixin OptionFields;
}


mixin template SimpleQueryAPIs()
{
    @trusted
    {
        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpSimple.html#HttpSimpleAll
         */
        Cursor!(T) queryAll(T = JSONValue)(const AllOption option = AllOption())
        {
            return queryAll!T(option);
        }

        /// ditto
        Cursor!(T) queryAll(T = JSONValue)(ref const AllOption option)
        {
            auto query = option.toJSONValue();
            query.object["collection"] = name_.toJSONValue();
            const request = Connection.Request(Method.PUT, buildSimpleQueryPath("all"), query.toJSON());
            auto response = database_.sendRequest(request);

            return typeof(return)(database_, response);
        }
    }

    @trusted
    {
        /**
         * See_Also: http://www.arangodb.org/manuals/current/OTWP.html#OTWPSimpleQueriesByExample
         */
        Document!(T)[] queryByExample(T = JSONValue, S)(S example, const ByExampleOption option = ByExampleOption())
        {
            return queryByExample!T(example, option);
        }

        /// ditto
        Document!(T)[] queryByExample(T = JSONValue, S)(S example, ref const ByExampleOption option)
        {
            auto query = option.toJSONValue();
            query.object["collection"] = name_.toJSONValue();
            query.object["example"] = example.toJSONValue();
            const request = Connection.Request(Method.PUT, buildSimpleQueryPath("by-example"), query.toJSON());
            auto response = database_.sendRequest(request);

            return response.object["result"].toDocuments!T;
        }
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpSimple.html#HttpSimpleFirstExample
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

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpSimple.html#HttpSimpleRange
     */
    @trusted
    T queryAny(T = JSONValue)()
    {
        const query = `{"collection":"` ~ name_ ~ `"}`;
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("any"), query);
        auto response = database_.sendRequest(request);

        return toDocument!T(response.object["document"]);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpSimple.html#HttpSimpleRange
     */
    @trusted
    Cursor!(T) queryRange(T = JSONValue)(ref const RangeOption option)
    {
        auto query = option.toJSONValue();
        query.object["collection"] = name_.toJSONValue();
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("range"), query.toJSON());
        auto response = database_.sendRequest(request);

        return typeof(return)(database_, response);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/IndexFulltextHttp.html#IndexFulltextHttpFulltext
     */
    @trusted
    Cursor!(T) queryFulltext(T = JSONValue)(ref const FulltextOption option)
    {
        auto query = option.toJSONValue();
        query.object["collection"] = name_.toJSONValue();
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("fulltext"), query.toJSON());
        auto response = database_.sendRequest(request);

        return typeof(return)(database_, response);
    }

    /**
     * See_Also: https://www.arangodb.org/manuals/current/HttpSimple.html#HttpSimpleFirst
     */
    @trusted
    Document!(T)[] firstN(T = JSONValue)(size_t count = 1)
    {
        return getN!T("first", count);
    }

    /**
     * See_Also: https://www.arangodb.org/manuals/current/HttpSimple.html#HttpSimpleLast
     */
    @trusted
    Document!(T)[] lastN(T = JSONValue)(size_t count = 1)
    {
        return getN!T("last", count);
    }

  private:
    @trusted
    Document!(T)[] getN(T = JSONValue)(string path, size_t count)
    {
        auto query = JSONValue(["collection" : name_]);
        if (count > 1)
            query.object["count"] = count.toJSONValue;
        const request = Connection.Request(Method.PUT, buildSimpleQueryPath(path), query.toJSON());
        auto response = database_.sendRequest(request);

        if (count > 1)
            return response.object["result"].toDocuments!T;
        else
            return [response.object["result"].toDocument!T];
    }

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

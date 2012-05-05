// Written in the D programming language.

module avocado.query;

import std.typecons : Nullable;

import avocado.database;

package
{
    immutable SimpleQueryAPIPath = Database.APIPrefix ~ "/simple";
}

struct ByExampleOption
{
    string collection;
    Nullable!long skip;
    Nullable!long limit;
}

mixin template SimpleQueryAPIs()
{
    /**
     * See_Also: http://www.avocadodb.org/manuals/OTWP.html#OTWPSimpleQueriesByExample
     */
    @trusted
    Document!(T)[] queryByExample(T = JSONValue, S)(S example, ref ByExampleOption option = ByExampleOption())
    {
        typeof(return) convertResponse(ref JSONValue response)
        {
            typeof(return) result;
            result.reserve(response.array.length);

            foreach (ref value; response.array) {
                auto newHandle = extractDocumentHandle(value);
                static if (is(T : JSONValue))
                {
                    result ~= Document!T(newHandle, value);
                }
                else
                {
                    result ~= Document!T(newHandle, fromJSONValue!T(value));
                }
            }

            return result;
        }

        option.collection = name_;
        auto query = option.toJSONValue();
        query.object["example"] = example.toJSONValue();

        const request = Connection.Request(Method.PUT, buildSimpleQueryPath("by-example"), query.toJSON());
        auto response = database_.sendRequest(request);

        return convertResponse(response);
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

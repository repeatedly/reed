// Written in the D programming language.

module reed.index;

import reed.database;
import reed.util;

package
{
    immutable IndexAPIPath = buildUriPath(Database.APIPrefix, "index");
}

private
{
    alias Connection.Method Method;

    mixin template IndexFields()
    {
        string id;
        string type;
        string[] fields;
        bool isNewlyCreated;
    }
}

struct Index
{
    mixin IndexFields;
}

struct HashIndex
{
    mixin IndexFields;
    bool unique;
}

struct HashIndexOption
{
    string[] fields;
    bool unique;
    string type = "hash";  // ugly! See http://d.puremagic.com/issues/show_bug.cgi?id=3449#c13
}

struct SkipListIndex
{
    mixin IndexFields;
    bool unique;
}

struct SkipListIndexOption
{
    string[] fields;
    bool unique;
    string type = "skiplist";  // See HashIndexOption
}

mixin template IndexAPIs()
{
    /**
     * See_Also: http://www.arangodb.org/manuals/HttpIndex.html#HttpIndexReadAll
     */
    @property @safe
    Index[] indexes() const
    {
        const request = Connection.Request(Method.GET, buildIndexPath());
        auto response = database_.sendRequest(request);

        return fromJSONValue!(Index[])(response.object["indexes"]);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/HttpIndex.html#HttpIndexRead
     */
    @safe
    T getIndex(T = Index)(in string id) const
    {
        const request = Connection.Request(Method.GET, buildIndexPath(id));
        auto response = database_.sendRequest(request);

        return fromJSONValue!T(response);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/HttpIndex.html#HttpIndexCreate
     */
    @safe
    auto createIndex(T)(auto ref const T option)
    {
        static if (is(T : HashIndexOption))
            alias HashIndex ReturnType;
        else static if (is(T : SkipListIndexOption))
            alias SkipListIndex ReturnType;
        else
            alias Index ReturnType;

        const jsonified = option.toJSONValue();
        const request = Connection.Request(Method.POST, buildIndexPath(), jsonified.toJSON());
        auto response = database_.sendRequest(request);

        return fromJSONValue!ReturnType(response);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/HttpIndex.html#HttpIndexDelete
     */
    @safe
    void deleteIndex(in string id)
    {
        const request = Connection.Request(Method.DELETE, buildIndexPath(id));
        database_.sendRequest(request);
    }

  private:
    @safe
    string buildIndexPath(string path) const
    {
        return buildUriPath(IndexAPIPath, path);
    }

    @trusted
    string buildIndexPath() const
    {
        import std.conv : text;
        return text(IndexAPIPath, "?collection=", id_);
    }
}

// Written in the D programming language.

module reed.cursor;

import std.array    : empty, front, popFront, array;
import std.typecons : Nullable;

import reed.database;
import reed.document;
import reed.util;

package
{
    immutable CursorAPIPath = buildUriPath(Database.APIPrefix, "cursor");
}

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

/**
 * See: http://www.arangodb.org/manuals/current/HttpCursor.html#HttpCursorHttp
 */
struct Cursor(T)
{
  private:
    bool hasMore_;
    string cursorId_;
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
        string id() const
        {
            return cursorId_;
        }

        long count() const
        {
            assert(count_, "Cannot call count on query without 'count' parameter");
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
            cursorId_ = value.object["id"].str;
        documents_ = value.object["result"].toDocuments!T;
        hasMore_ = value.object["hasMore"].type == std.json.JSON_TYPE.TRUE;
    }
}

mixin template CursorAPIs()
{
    @trusted
    {
        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpCursor.html#HttpCursorHttp
         */
        Cursor!(T) queryCursor(T = JSONValue)(in string aqlQuery, const CursorOption option = CursorOption())
        {
            return queryCursor(aqlQuery, option);
        }

        /// ditto
        Cursor!(T) queryCursor(T = JSONValue)(in string aqlQuery, ref const CursorOption option)
        {
            auto query = option.toJSONValue();
            query.object["query"] = aqlQuery.toJSONValue();
            const request = Connection.Request(Method.POST, CursorAPIPath, query.toJSON());
            auto response = sendRequest(request);

            return typeof(return)(this, response);
        }
    }
}

package:

@safe
string buildCursorPath(string id) // pure
{
    return buildUriPath(CursorAPIPath, id);
}

// Written in the D programming language.

module reed.database;

import std.conv     : to, text;
import std.json     : parseJSON, JSONValue;
import std.typecons : Nullable;
import std.net.curl : get, put, post, del, HTTP;

import reed.bulk_import;
import reed.util;

public
{
    import reed.admin;
    import reed.collection;
    import reed.document;
}

private
{
    alias Connection.Method Method;
}

struct Configuration
{
    Connection.Endpoint endpoint;
    string database;
}

class Database
{
  public:
    static immutable APIPrefix = "_api";

    static struct CollectionProperty
    {
        string name;
        Nullable!bool isSystem;
        Nullable!bool isVolatile;
        Nullable!bool waitForSync;
        Nullable!long journalSize;
    }

  private:
    string name_;
    Connection connection_;

  public:
    @safe
    this(const Configuration config = Configuration())
    {
        connection_ = new Connection(config);
    }

    @safe
    this(ref const Configuration config)
    {
        connection_ = new Connection(config);
    }

    @property
    {
        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpCollection.html#HttpCollectionReadAll
         */
        inout(Collection[]) collections(bool excludeSystem = false) inout
        {
            @trusted
            string buildPath()
            {
                return text(Collection.APIPath, "?excludeSystem=", excludeSystem);
            }

            const request = Connection.Request(Method.GET, buildPath());
            const response = sendRequest(request);

            Collection[] result;
            foreach (collection; response.object["collections"].array)
                result ~= new Collection(cast()this, collection);

            return cast(typeof(return))result;
        }
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpCollection.html#HttpCollectionCreate
     */
    @safe
    DocumentHandle putDocument(T)(in string collectionName, auto ref const T document)
    {
        @trusted
        string buildPath()
        {
            return text(DocumentAPIPath, "?collection=", collectionName, "&createCollection=true");
        }

        const jsonified = document.toJSONValue();
        const request = Connection.Request(Method.POST, buildPath(), jsonified.toJSON());
        const response = sendRequest(request);

        return fromJSONValue!DocumentHandle(response);
    }

    @safe
    {
        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpCollection.html#HttpCollectionCreate
         */
        Collection createCollection(const CollectionProperty properties)
        {
            return createCollection(properties);
        }

        /// ditto
        Collection createCollection(ref const CollectionProperty properties)
        {
            const jsonified = properties.toJSONValue();
            const request = Connection.Request(Method.POST, Collection.APIPath, jsonified.toJSON());
            const response = sendRequest(request);

            return new Collection(this, response);
        }
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpCollection.html#HttpCollectionDelete
     */
    @trusted
    void deleteCollection(in ulong id)
    {
        deleteCollection(id.to!string()); // @trusted because of to!string is @system
    }

    /// ditto
    @trusted
    void deleteCollection(in string name)
    {
        const request = Connection.Request(Method.DELETE, buildUriPath(Collection.APIPath, name));
        const response = sendRequest(request);
        // TODO : return to deleted id?
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpCollection.html#HttpCollectionRead
     */
    @trusted
    inout(Collection) opIndex(ulong id) inout
    {
        return opIndex(id.to!string()); // see deleteCollection
    }

    /// ditto
    @trusted
    inout(Collection) opIndex(string name) inout
    {
        const request = Connection.Request(Method.GET, buildUriPath(Collection.APIPath, name));
        const response = sendRequest(request);

        return new typeof(return)(this, response);
    }

    mixin CursorAPIs;
    mixin AdminAPIs;
    mixin BulkImportAPIs;

    // TODO: Clean up
    @safe
    JSONValue sendRequest(ref const Connection.Request request)
    {
        return connection_.sendRequest(request);
    }

    @safe
    JSONValue sendRequest(ref const Connection.Request request) const
    {
        return connection_.sendRequest(request);
    }
}

class Connection
{
  public:
    static struct Endpoint
    {
        string host = "127.0.0.1";
        ushort port = 8529;
    }

    enum Method
    {
        GET, POST, PUT, DELETE
    }

    static struct Request
    {
        Method method;
        string path;
        string content;
    }

  private:
    Endpoint endpoint_;
    string baseUri_;

  public:
    @trusted
    this(ref const Configuration config)
    {
        endpoint_ = config.endpoint;
        if (config.database.empty)
            baseUri_ = text("http://", endpoint_.host, ":", endpoint_.port);
        else
            baseUri_ = text("http://", endpoint_.host, ":", endpoint_.port, "/_db/", config.database);
    }

    @trusted
    JSONValue sendRequest(ref const Request request)
    {
        immutable uri = buildUriPath(baseUri_, request.path);
        auto client = HTTP();
        char[] response;

        final switch (request.method) {
        case Method.GET:
            response = get(uri, client);
            break;
        case Method.POST:
            response = post(uri, request.content, client);
            break;
        case Method.PUT:
            response = put(uri, request.content, client);
            break;
        case Method.DELETE:
            response = "{}".dup;
            del(uri); // TODO: See issue 8025 http://d.puremagic.com/issues/show_bug.cgi?id=8025
            break;
        }

        return parseJSON(response);
    }

    @trusted
    JSONValue sendRequest(ref const Request request) const
    {
        immutable uri = buildUriPath(baseUri_, request.path);
        auto client = HTTP();
        char[] response;

        final switch (request.method) {
        case Method.GET:
            response = get(uri, client);
            break;
        case Method.POST:
        case Method.PUT:
        case Method.DELETE:
            throw new Exception("const method cannot use POST, PUT and DELETE methods");
        }

        return parseJSON(response);
    }
}

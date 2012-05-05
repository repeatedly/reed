// Written in the D programming language.

module avocado.database;

import std.conv     : to, text;
import std.json     : parseJSON, JSONValue;
import std.typecons : Nullable;
import std.net.curl : get, put, post, del;

import avocado.collection;
import avocado.util;

private
{
    alias Connection.Method Method;
}

struct Configuration
{
    Connection.Endpoint endpoint;
}

class Database
{
  public:
    immutable APIPrefix = "_api";

    static struct CollectionProperty
    {
        string name;
        Nullable!bool isSystem;
        Nullable!bool waitForSync;
        Nullable!long journalSize;
    }

  private:
    Connection connection_;

  public:
    @safe
    this(ref const Configuration config)
    {
        connection_ = new Connection(config.endpoint);
    }

    @property
    {
        /**
         * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionReadAll
         */
        inout(Collection[]) collections() inout
        {
            const request = Connection.Request(Method.GET, Collection.APIPath);
            const response = sendRequest(request);

            Collection[] result;
            foreach (collection; response.object["collections"].array)
                result ~= new Collection(cast()this, collection);

            return cast(typeof(return))result;
        }
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionCreate
     */
    @safe
    Collection createCollection(ref const CollectionProperty properties)
    {
        const jsonified = properties.toJSONValue();
        const request = Connection.Request(Method.POST, Collection.APIPath, jsonified.toJSON());
        const response = sendRequest(request);

        return new Collection(this, response);
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionDelete
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
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRead
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

        return new typeof(return)(cast()this, response);
    }

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
    this(ref const Endpoint endpoint)
    {
        endpoint_ = endpoint;
        baseUri_ = text("http://", endpoint_.host, ":", endpoint.port);
    }

    @trusted
    JSONValue sendRequest(ref const Request request)
    {
        immutable uri = buildUriPath(baseUri_, request.path);
        char[] response;

        final switch (request.method) {
        case Method.GET:
            response = get(uri);
            break;
        case Method.POST:
            response = post(uri, request.content);
            break;
        case Method.PUT:
            response = put(uri, request.content);
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
        char[] response;

        final switch (request.method) {
        case Method.GET:
            response = get(uri);
            break;
        case Method.POST:
        case Method.PUT:
        case Method.DELETE:
            throw new Exception("const method cannot use POST, PUT and DELETE methods");
        }

        return parseJSON(response);
    }
}

// Written in the D programming language.

module avocado.database;

import std.conv     : to, text;
import std.json     : parseJSON, JSONValue;
import std.typecons : Nullable;
import std.net.curl : get, put, post, del;

import avocado.util;

private
{
    enum REST
    {
        GET, POST, PUT, DELETE
    }

    immutable RootAPIPath = "_api";
    immutable CollectionAPIPath = RootAPIPath ~ "/collection";
}

struct Configuration
{
    string host = "127.0.0.1";
    ushort port = 8529;
}

class Database
{
  public:
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
        connection_ = new Connection(config);
    }

    @property
    {
        /**
         * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionReadAll
         */
        inout(Collection[]) collections() inout
        {
            const request = Connection.Request(REST.GET, CollectionAPIPath);
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
        const request = Connection.Request(REST.POST, CollectionAPIPath, jsonified.toJSON());
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
        const request = Connection.Request(REST.DELETE, buildUriPath(CollectionAPIPath, name));
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
        const request = Connection.Request(REST.GET, buildUriPath(CollectionAPIPath, name));
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

class Collection
{
  public:
    static struct Property
    {
        long journalSize;
        bool waitForSync;
    }

    static struct Figure
    {
        static struct Alive
        {
            long count;
            long size;
        }

        static struct Dead
        {
            long count;
            long size;
            long deletion;
        }

        static struct DataFiles
        {
            long count;
        }

        Alive alive;
        Dead dead;
        DataFiles dataFiles;
    }

  private:
    Database database_;
    string name_;
    ulong id_;
    uint status_;

  public:
    @trusted
    this(Database database, ref const JSONValue info)
    {
        database_ = database;

        if ("name" in info.object)
            name_ = info.object["name"].str;
        if ("id" in info.object)
            id_ = info.object["id"].integer;
        if ("status" in info.object)
            status_ = info.object["status"].integer.to!uint();
    }

    @property @safe
    {
        nothrow ulong id() const
        {
            return id_;
        }

        nothrow string name() const
        {
            return name_;
        }

        /**
         * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRename
         */
        void name(string newName)
        {
            const jsonified = ["name": newName].toJSONValue();
            const request = Connection.Request(REST.PUT, buildOwnPath("rename"), jsonified.toJSON());
            const response = database_.sendRequest(request);

            name_ = newName;
        }

        /**
         * See_Also: size of http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRead
         */
        @trusted
        size_t length() const
        {
            const request = Connection.Request(REST.GET, buildOwnPath("count"));
            const response = database_.sendRequest(request);

            return cast(size_t)response.object["count"].integer;
        }

        /**
         * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionProperties
         */
        void waitForSync(bool newWaitForSync)
        {
            const jsonified = ["waitForSync": newWaitForSync].toJSONValue();
            const request = Connection.Request(REST.PUT, buildOwnPath("properties"), jsonified.toJSON());
            database_.sendRequest(request);
        }

        /**
         * See_Also: properties of http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRead
         */
        Property property() const
        {
            const request = Connection.Request(REST.GET, buildOwnPath("properties"));
            const response = database_.sendRequest(request);

            return fromJSONValue!Property(response);
        }

        /**
         * See_Also: figures of http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRead
         */
        Figure figure() const
        {
            const request = Connection.Request(REST.GET, buildOwnPath("figures"));
            const response = database_.sendRequest(request);

            return fromJSONValue!Figure(response.object["figures"]);
        }
    }

    @property @safe nothrow const
    {
        /**
         * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionReading
         */
        bool isNewBorned()
        {
            // Shoulde get status from database?
            return status_ == 1;
        }

        bool isUnloaded()
        {
            return status_ == 2;
        }

        bool isLoaded()
        {
            return status_ == 3;
        }

        bool isBeingUnloaded()
        {
            return status_ == 4;
        }

        bool isDeleted()
        {
            return status_ == 5;
        }

        bool isCorrupted()
        {
            return status_ > 5;
        }
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionLoad
     */
    @safe
    void load()
    {
        const request = Connection.Request(REST.PUT, buildOwnPath("load"));
        database_.sendRequest(request);
        status_ = 3;
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionUnload
     */
    @safe
    void unload()
    {
        const request = Connection.Request(REST.PUT, buildOwnPath("unload"));
        database_.sendRequest(request);
        status_ = 2;
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionTruncate
     */
    @safe
    void truncate()
    {
        const request = Connection.Request(REST.PUT, buildOwnPath("truncate"));
        database_.sendRequest(request);
    }

  private:
    @safe
    string buildOwnPath(string path) const
    {
        return buildUriPath(CollectionAPIPath, id_, path);
    }
}

class Connection
{
  private:
    static struct Request
    {
        REST method;
        string path;
        string content;
    }

    Configuration config_;
    string baseUri_;

  public:
    @trusted
    this(ref const Configuration config)
    {
        config_ = config;
        baseUri_ = text("http://", config_.host, ":", config.port);
    }

    @trusted
    JSONValue sendRequest(ref const Request request)
    {
        immutable uri = buildUriPath(baseUri_, request.path);
        char[] response;

        final switch (request.method) {
        case REST.GET:
            response = get(uri);
            break;
        case REST.POST:
            response = post(uri, request.content);
            break;
        case REST.PUT:
            response = put(uri, request.content);
            break;
        case REST.DELETE:
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
        case REST.GET:
            response = get(uri);
            break;
        case REST.POST:
        case REST.PUT:
        case REST.DELETE:
            throw new Exception("const method cannot use POST, PUT and DELETE methods");
        }

        return parseJSON(response);
    }
}

private:

@safe
string buildUriPath(Paths...)(Paths paths)
{
    import std.algorithm;

    @safe
    static typeof(return) joinPaths(in string lhs, in string rhs) pure nothrow
    {
        return lhs ~ "/" ~ rhs;
    }

    @trusted
    string[] pathsToStringArray() //TODO: pure nothrow (because of to!string)
    {
        auto result = new string[](paths.length);
        foreach (i, path; paths)
            result[i] = path.to!string();
        return result;
    }

    return reduce!joinPaths(pathsToStringArray());
}

unittest
{
    assert(buildUriPath("") == "");
    assert(buildUriPath("handa") == "handa");
    assert(buildUriPath("handa", "shinobu") == "handa/shinobu");
    assert(buildUriPath("handa", 18UL) == "handa/18");
}

// Written in the D programming language.

module avocado.collection;

import avocado.database;
import avocado.util;

private
{
    alias Connection.Method Method;
}

class Collection
{
  public:
    immutable APIPath = Database.APIPrefix ~ "/collection";

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
            const request = Connection.Request(Method.PUT, buildOwnPath("rename"), jsonified.toJSON());
            const response = database_.sendRequest(request);

            name_ = newName;
        }

        /**
         * See_Also: size of http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRead
         */
        @trusted
        size_t length() const
        {
            const request = Connection.Request(Method.GET, buildOwnPath("count"));
            const response = database_.sendRequest(request);

            return cast(size_t)response.object["count"].integer;
        }

        /**
         * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionProperties
         */
        void waitForSync(bool newWaitForSync)
        {
            const jsonified = ["waitForSync": newWaitForSync].toJSONValue();
            const request = Connection.Request(Method.PUT, buildOwnPath("properties"), jsonified.toJSON());
            database_.sendRequest(request);
        }

        /**
         * See_Also: properties of http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRead
         */
        Property property() const
        {
            const request = Connection.Request(Method.GET, buildOwnPath("properties"));
            const response = database_.sendRequest(request);

            return fromJSONValue!Property(response);
        }

        /**
         * See_Also: figures of http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionRead
         */
        Figure figure() const
        {
            const request = Connection.Request(Method.GET, buildOwnPath("figures"));
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
        const request = Connection.Request(Method.PUT, buildOwnPath("load"));
        database_.sendRequest(request);
        status_ = 3;
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionUnload
     */
    @safe
    void unload()
    {
        const request = Connection.Request(Method.PUT, buildOwnPath("unload"));
        database_.sendRequest(request);
        status_ = 2;
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/HttpCollection.html#HttpCollectionTruncate
     */
    @safe
    void truncate()
    {
        const request = Connection.Request(Method.PUT, buildOwnPath("truncate"));
        database_.sendRequest(request);
    }

  private:
    @safe
    string buildOwnPath(string path) const
    {
        return buildUriPath(APIPath, id_, path);
    }
}

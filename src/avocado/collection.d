// Written in the D programming language.

module avocado.collection;

import avocado.database;
import avocado.document;
import avocado.util;

public
{
    import avocado.document : DocumentHandle;
}

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

    /// Document APIs

    /**
     * See_Also: http://www.avocadodb.org/manuals/RestDocument.html#RestDocumentCreate
     */
    @safe
    T getDocument(T = JSONValue)(ulong revision) const
    {
        return getDocument(DocumentHandle(id_, revision));
    }

    /// ditto
    @safe
    T getDocument(T = JSONValue)(ref const DocumentHandle handle) const
    {
        const request = Connection.Request(Method.GET, buildDocumentPath(handle));
        auto response = database_.sendRequest(request);
        static if (is(T : JSONValue))
        {
            return response;
        }
        else
        {
            response.object.remove("_id");
            response.object.remove("_rev");
            return fromJSONValue!T(response);
        }
    }

    // T getDocument(T = JSONValue)(ref const DocumentHandle handle, ulong etag, bool match = true) const

    /**
     * See_Also: http://www.avocadodb.org/manuals/RestDocument.html#RestDocumentReadAll
     */
    @safe
    string[] getDocumentURIs() const
    {
        @trusted
        string buildPath()
        {
            return text(DocumentAPIPath, "?collection=", id_);
        }

        const request = Connection.Request(Method.GET, buildPath());
        const response = database_.sendRequest(request);

        return fromJSONValue!(string[])(response.object["documents"]);
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/RestDocument.html#RestDocumentCreate
     */
    @safe
    DocumentHandle putDocument(T)(auto ref const T document)
    {
        @trusted
        string buildPath()
        {
            return text(DocumentAPIPath, "?collection=", id_);
        }

        const jsonified = document.toJSONValue();
        const request = Connection.Request(Method.POST, buildPath(), jsonified.toJSON());
        const response = database_.sendRequest(request);

        return fromJSONValue!DocumentHandle(response);
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/RestDocument.html#RestDocumentUpdate
     */
    @safe
    DocumentHandle updateDocument(T)(ulong revision, auto ref const T document)
    {
        return updateDocument(DocumentHandle(id_, revision), document);
    }

    /// ditto
    @safe
    DocumentHandle updateDocument(T)(ref const DocumentHandle handle, auto ref const T document)
    {
        const jsonified = document.toJSONValue();
        const request = Connection.Request(Method.PUT, buildDocumentPath(handle), jsonified.toJSON());
        const response = database_.sendRequest(request);

        return fromJSONValue!DocumentHandle(response);
    }

    /**
     * See_Also: http://www.avocadodb.org/manuals/RestDocument.html#RestDocumentHead
     * Issue: http://d.puremagic.com/issues/show_bug.cgi?id=8048
     */
    // bool checkDocument(ref const DocumentHandle handle) nothrow

    /**
     * See_Also: http://www.avocadodb.org/manuals/RestDocument.html#RestDocumentDelete
     */
    @safe
    void deleteDocument(ulong revision)
    {
        return deleteDocument(DocumentHandle(id_, revision));
    }

    /// ditto
    @safe
    void deleteDocument(ref const DocumentHandle handle)
    {
        // TODO: Support support policy
        const request = Connection.Request(Method.DELETE, buildDocumentPath(handle));
        database_.sendRequest(request);
    }

    // void deleteDocument(ref const DocumentHandle handle, ulong etag)

  private:
    @safe
    string buildOwnPath(string path) const
    {
        return buildUriPath(APIPath, id_, path);
    }
}

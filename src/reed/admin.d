// Written in the D programming language.

module reed.admin;

import reed.util;

import std.typecons : Nullable;

package
{
    immutable AdminAPIPath = "_admin";
}

struct Statistics
{
    static struct SystemInfo
    {
        real userTime;
        real systemTime;
        size_t numberOfThreads;
        size_t residentSize;
        real residentSizePercent;
        size_t virtualSize;
        size_t minorPageFaults;
        size_t majorPageFaults;
    }

    static struct ClientInfo
    {
        static struct Distribution
        {
            real sum;
            size_t count;
            size_t[] counts;
        }

        size_t httpConnections;
        Distribution connectionTime;
        Distribution totalTime;
        Distribution requestTime;
        Distribution queueTime;
        Distribution bytesSent;
        Distribution bytesReceived;
    }

    static struct HTTPInfo
    {
        size_t requestsTotal;
        size_t requestsAsync;
        size_t requestsGet;
        size_t requestsHead;
        size_t requestsPost;
        size_t requestsPut;
        size_t requestsPatch;
        size_t requestsDelete;
        size_t requestsOptions;
        size_t requestsOther;
    }

    static struct ServerInfo
    {
        real uptime;
        size_t physicalMemory;
    }

    SystemInfo system;
    ClientInfo client;
    HTTPInfo http;
    ServerInfo server;
    bool error;
    uint code;
}

struct LogEntries
{
    ubyte[] level;
    size_t[] lid;
    size_t[] timestamp;
    string[] text;
    size_t totalAmount;
}

struct EchoResult
{
    string user;
    string path;
    string prefix;
    string[] suffix;
    string requestType;
    string[string] headers;
    string[string] parameters;
}

mixin template AdminAPIs()
{
  public:
    @property @trusted
    {
        /**
         * See_Also: https://www.arangodb.org/manuals/current/HttpSystem.html#HttpSystemAdminStatistics
         */
        Statistics statistics() const
        {
            enum path = buildUriPath(AdminAPIPath, "statistics");
            const req = Connection.Request(Method.GET, path);
            const res = sendRequest(req);

            return fromJSONValue!Statistics(res);
        }

        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpSystem.html#HttpSystemLog
         */
        LogEntries log(in string[string] params = null) const
        {
            enum path = buildUriPath(AdminAPIPath, "log");
            const req = Connection.Request(Method.GET, path ~ joinParameters(params));
            const res = sendRequest(req);

            return fromJSONValue!LogEntries(res);
        }

        /**
         * See_Also: https://www.arangodb.org/manuals/current/HttpMisc.html#HttpMiscVersion
         */
        string serverVersion() const
        {
            enum path = buildUriPath(AdminAPIPath, "version");
            const req = Connection.Request(Method.GET, path);
            const res = sendRequest(req);

            return res.object["version"].str;
        }

        /**
         * See_Also: https://www.arangodb.org/manuals/current/HttpMisc.html#HttpMiscTime
         */
        real serverTime() const
        {
            enum path = buildUriPath(AdminAPIPath, "time");
            const req = Connection.Request(Method.GET, path);
            const res = sendRequest(req);

            return res.object["time"].floating;
        }

        string serverRole() const
        {
            enum path = buildUriPath(AdminAPIPath, "server/role");
            const req = Connection.Request(Method.GET, path);
            const res = sendRequest(req);

            return res.object["role"].str;
        }
    }

    /**
     * See_Also: https://www.arangodb.org/manuals/current/HttpMisc.html#HttpMiscEcho
     */
    @safe
    EchoResult echo() const
    {
        enum path = buildUriPath(AdminAPIPath, "echo");
        const req = Connection.Request(Method.GET, path);
        const res = sendRequest(req);

        return fromJSONValue!EchoResult(res);
    }

    /**
     * See_Also: https://www.arangodb.org/manuals/current/HttpSystem.html#HttpSystemFlushServerModules
     */
    @safe
    void flushModules()
    {
        enum path = buildUriPath(AdminAPIPath, "modules/flush");
        const req = Connection.Request(Method.POST, path, "");
        const res = sendRequest(req);
    }

    /**
     * See_Also: https://www.arangodb.org/manuals/current/HttpSystem.html#HttpSystemRoutingReloads
     */
    @safe
    void reloadRouting()
    {
        enum path = buildUriPath(AdminAPIPath, "routing/reload");
        const req = Connection.Request(Method.POST, path, "");
        const res = sendRequest(req);
    }
}


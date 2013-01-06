// Written in the D programming language.

module reed.admin;

import reed.util;

import std.typecons : Nullable;

package
{
    immutable AdminAPIPath = "_admin";
}

struct SystemStatus
{
    real userTime;
    real systemTime;
    size_t numberOfThreads;
    size_t residentSize;
    size_t virtualSize;
    size_t minorPageFaults;
    size_t majorPageFaults;
}

struct LogEntries
{
    ubyte[] level;
    size_t[] lid;
    size_t[] timestamp;
    string[] text;
    size_t totalAmount;
}

struct ConnectionStatistics
{
    static struct Distribution
    {
        real[3] cuts;
        size_t[] count;
        real[] mean;
        real[] min;
        size_t[4][] distribution;
    }

    static struct HttpConnections
    {
        size_t[] count;
        real[] perSecond;
    }

    size_t resolution;
    size_t length;
    size_t totalLength;
    size_t[] start;
    Nullable!HttpConnections httpConnections;
    Nullable!Distribution httpDuration;
}

struct CurrentConnectionStatistics
{
    static struct Distribution
    {
        real[3] cuts;
        size_t count;
        real mean;
        real min;
        size_t[4] distribution;
    }

    static struct HttpConnections
    {
        size_t count;
        real perSecond;
    }

    size_t resolution;
    size_t start;
    Nullable!HttpConnections httpConnections;
    Nullable!Distribution httpDuration;
}

struct RequestStatistics
{
    mixin template DistributionFields()
    {
        size_t[] count;
        real[] mean;
        real[] min;
    }

    static struct TimeDistribution
    {
        mixin DistributionFields;

        real[6] cuts;
        size_t[7][] distribution;
    }

    static struct BytesDistribution
    {
        mixin DistributionFields;

        real[5] cuts;
        size_t[6][] distribution;
    }

    size_t resolution;
    size_t length;
    size_t totalLength;
    size_t[] start;
    Nullable!TimeDistribution totalTime;
    Nullable!TimeDistribution queueTime;
    Nullable!TimeDistribution requestTime;
    Nullable!BytesDistribution bytesSent;
    Nullable!BytesDistribution bytesReceived;
}

struct CurrentRequestStatistics
{
    mixin template DistributionFields()
    {
        size_t count;
        real mean;
        real min;
    }

    static struct TimeDistribution
    {
        mixin DistributionFields;

        real[6] cuts;
        size_t[7] distribution;
    }

    static struct BytesDistribution
    {
        mixin DistributionFields;

        real[5] cuts;
        size_t[6] distribution;
    }

    size_t resolution;
    size_t length;
    Nullable!TimeDistribution totalTime;
    Nullable!TimeDistribution queueTime;
    Nullable!TimeDistribution requestTime;
    Nullable!BytesDistribution bytesSent;
    Nullable!BytesDistribution bytesReceived;
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
  private:
    @safe
    Type statisticsFunc(Type, string apiPath)(in string[string] params = null) const
    {
        enum path = buildUriPath(AdminAPIPath, apiPath);
        const req = Connection.Request(Method.GET, path ~ joinParameters(params));
        const res = sendRequest(req);

        return fromJSONValue!Type(res);
    }

    @safe
    Type currentStatisticsFunc(Type, string apiPath)(in string[string] params = null) const
    {
        string[string] curParams = ["length":"current"];
        foreach (k, ref v; params) {
            if (k != "length")
                curParams[k] = v;
        }

        enum path = buildUriPath(AdminAPIPath, apiPath);
        const req = Connection.Request(Method.GET, path ~ joinParameters(curParams));
        const res = sendRequest(req);

        return fromJSONValue!Type(res);
    }

  public:
    @property @safe
    {
        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpSystem.html#HttpSystemStatus
         */
        SystemStatus status() const
        {
            enum path = buildUriPath(AdminAPIPath, "status");
            const req = Connection.Request(Method.GET, path);
            const res = sendRequest(req);

            return fromJSONValue!SystemStatus(res.object["system"]);
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
         * See_Also: http://www.arangodb.org/manuals/current/HttpSystem.html#HttpSystemConnectionStatistics
         */
        alias statisticsFunc!(ConnectionStatistics, "connection-statistics") connectionStatistics;
        alias currentStatisticsFunc!(CurrentConnectionStatistics, "connection-statistics") currentConnectionStatistics;

        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpSystem.html#HttpSystemRequestStatistics
         */
        alias statisticsFunc!(RequestStatistics, "request-statistics") requestStatistics;
        alias currentStatisticsFunc!(CurrentRequestStatistics, "request-statistics") currentRequestStatistics;

        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpMisc.html#HttpMiscVersion
         */
        string serverVersion() const
        {
            enum path = buildUriPath(AdminAPIPath, "version");
            const req = Connection.Request(Method.GET, path);
            const res = sendRequest(req);

            return res.object["version"].str;
        }

        /**
         * See_Also: http://www.arangodb.org/manuals/current/HttpMisc.html#HttpMiscTime
         */
        real serverTime() const
        {
            enum path = buildUriPath(AdminAPIPath, "time");
            const req = Connection.Request(Method.GET, path);
            const res = sendRequest(req);

            return res.object["time"].floating;
        }

    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpMisc.html#HttpMiscEcho
     */
    @safe
    EchoResult echo() const
    {
        enum path = buildUriPath(AdminAPIPath, "echo");
        const req = Connection.Request(Method.GET, path);
        const res = sendRequest(req);

        return fromJSONValue!EchoResult(res);
    }
}


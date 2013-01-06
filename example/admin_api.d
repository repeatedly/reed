import reed.database;

import core.time;

import std.stdio;
import std.conv;
import std.math;

void main()
{
    auto database = new Database();

    writeln("Get system status");

    auto status = database.status();
    {
        assert(status.userTime > 0.0);
        assert(status.systemTime > 0.0);
        assert(status.numberOfThreads >= 0);
        assert(status.residentSize > 0);
        assert(status.virtualSize >= 0);
        assert(status.minorPageFaults >= 0);
        assert(status.majorPageFaults >= 0);
    }

    writeln("Get system logs");

    foreach (params; [["upto":"2"], ["level": "3"], ["start":"10"],
                      ["sort":"asc"], ["sort":"desc"], ["search":"redbull"],
                      ["size":"5", "offset":"5"], null]) {
        auto logs = database.log(params);

        assert(logs.level.length >= 0);
        assert(logs.lid.length >= 0);
        assert(logs.timestamp.length >= 0);
        assert(logs.text.length >= 0);
        assert(logs.totalAmount >= 0);
    }

    long calcResolution(in string unit)
    {
        switch (unit) {
        case "minutes":
            return 60;
        case "hours":
            return 60 * 60;
        case "days":
            return 24 * 60 * 60;
        default:
            assert(false);
        }
    }

    writeln("Get connection statistics");

    void checkLength(Stats)(ref Stats stats)
    {
        assert(stats.totalLength >= stats.length);

        assert(stats.httpConnections.count.length == stats.length);
        assert(stats.httpConnections.perSecond.length == stats.length);

        assert(stats.httpDuration.min.length == stats.length);
        assert(stats.httpDuration.mean.length == stats.length);
        assert(stats.httpDuration.count.length == stats.length);
        assert(stats.httpDuration.distribution.length == stats.length);
    }

    auto connStats = database.connectionStatistics;
    {
        assert(connStats.resolution == calcResolution("minutes"));
        checkLength(connStats);
    }

    foreach (params; [["granularity":"minutes"], ["granularity":"hours"], ["granularity":"days"]]) {
        auto stats = database.connectionStatistics(params);

        assert(stats.resolution == calcResolution(params["granularity"]));
        checkLength(stats);
    }

    foreach (params; [["figures":"httpConnections"], ["figures":""]]) {
        auto stats = database.connectionStatistics(params);

        if (!stats.httpDuration.isNull)
            checkLength(stats);
    }

    foreach (params; [["length":"1"], ["length":"2"], ["length":"4"]]) {
        auto stats = database.connectionStatistics(params);

        assert(stats.length == to!size_t(params["length"]));
        checkLength(stats);
    }

    foreach (params; [["granularity":"minutes"], ["granularity":"hours"], ["granularity":"days"]]) {
        auto stats = database.currentConnectionStatistics(params);

        assert(stats.resolution == calcResolution(params["granularity"]));
        assert(stats.httpConnections.count >= 0);
        assert(stats.httpConnections.perSecond >= 0.0);

        assert(stats.httpDuration.min >= 0);
        assert(!stats.httpDuration.mean.isInfinity);
        assert(stats.httpDuration.count >= 0);
        assert(stats.httpDuration.distribution.length == 4);
    }

    writeln("Get request statistics");

    void checkReqLength(Stats)(ref Stats stats)
    {
        assert(stats.totalLength >= stats.length);

        if (!stats.totalTime.isNull) {
            assert(stats.totalTime.min.length == stats.length);
            assert(stats.totalTime.mean.length == stats.length);
            assert(stats.totalTime.count.length == stats.length);
            assert(stats.totalTime.distribution.length == stats.length);
        }

        if (!stats.queueTime.isNull) {
            assert(stats.queueTime.min.length == stats.length);
            assert(stats.queueTime.mean.length == stats.length);
            assert(stats.queueTime.count.length == stats.length);
            assert(stats.queueTime.distribution.length == stats.length);
        }

        if (!stats.requestTime.isNull) {
            assert(stats.requestTime.min.length == stats.length);
            assert(stats.requestTime.mean.length == stats.length);
            assert(stats.requestTime.count.length == stats.length);
            assert(stats.requestTime.distribution.length == stats.length);
        }

        if (!stats.bytesSent.isNull) {
            assert(stats.bytesSent.min.length == stats.length);
            assert(stats.bytesSent.mean.length == stats.length);
            assert(stats.bytesSent.count.length == stats.length);
            assert(stats.bytesSent.distribution.length == stats.length);
        }

        if (!stats.bytesReceived.isNull) {
            assert(stats.bytesReceived.min.length == stats.length);
            assert(stats.bytesReceived.mean.length == stats.length);
            assert(stats.bytesReceived.count.length == stats.length);
            assert(stats.bytesReceived.distribution.length == stats.length);
        }
    }

    auto reqStats = database.requestStatistics;
    {
        assert(reqStats.resolution == calcResolution("minutes"));
        checkReqLength(reqStats);
    }

    foreach (params; [["granularity":"minutes"], ["granularity":"hours"], ["granularity":"days"]]) {
        auto stats = database.requestStatistics(params);

        assert(stats.resolution == calcResolution(params["granularity"]));
        checkReqLength(stats);
    }

    foreach (params; [["figures":"totalTime"], ["figures":"queueTime"],
                      ["figures":"requestTime"], ["figures":"bytesSent"],
                      ["figures":"bytesReceived"], ["figures":""]]) {
        auto stats = database.requestStatistics(params);

        auto dist = params["figures"];

        switch (dist) {
        case "totalTime":
            assert(!stats.totalTime.isNull);
            assert(stats.queueTime.isNull);
            assert(stats.requestTime.isNull);
            assert(stats.bytesSent.isNull);
            assert(stats.bytesReceived.isNull);
            break;
        case "queueTime":
            assert(stats.totalTime.isNull);
            assert(!stats.queueTime.isNull);
            assert(stats.requestTime.isNull);
            assert(stats.bytesSent.isNull);
            assert(stats.bytesReceived.isNull);
            break;
        case "requestTime":
            assert(stats.totalTime.isNull);
            assert(stats.queueTime.isNull);
            assert(!stats.requestTime.isNull);
            assert(stats.bytesSent.isNull);
            assert(stats.bytesReceived.isNull);
            break;
        case "bytesSent":
            assert(stats.totalTime.isNull);
            assert(stats.queueTime.isNull);
            assert(stats.requestTime.isNull);
            assert(!stats.bytesSent.isNull);
            assert(stats.bytesReceived.isNull);
            break;
        case "bytesReceived":
            assert(stats.totalTime.isNull);
            assert(stats.queueTime.isNull);
            assert(stats.requestTime.isNull);
            assert(stats.bytesSent.isNull);
            assert(!stats.bytesReceived.isNull);
            break;
        default:
            assert(stats.totalTime.isNull);
            assert(stats.queueTime.isNull);
            assert(stats.requestTime.isNull);
            assert(stats.bytesSent.isNull);
            assert(stats.bytesReceived.isNull);
            break;
        }

        checkReqLength(stats);
    }

    foreach (params; [["length":"1"], ["length":"2"], ["length":"4"]]) {
        auto stats = database.requestStatistics(params);

        assert(stats.length == to!size_t(params["length"]));
        checkReqLength(stats);
    }

    foreach (params; [["granularity":"minutes"], ["granularity":"hours"], ["granularity":"days"]]) {
        auto stats = database.currentRequestStatistics(params);
        {
            assert(stats.resolution == calcResolution(params["granularity"]));

            assert(stats.totalTime.min >= 0);
            assert(!stats.totalTime.mean.isInfinity);
            assert(stats.totalTime.count >= 0);
            assert(stats.totalTime.distribution.length == 7);

            assert(stats.bytesSent.min >= 0);
            assert(!stats.bytesSent.mean.isInfinity);
            assert(stats.bytesSent.count >= 0);
            assert(stats.bytesSent.distribution.length == 6);

            assert(stats.bytesReceived.min >= 0);
            assert(!stats.bytesReceived.mean.isInfinity);
            assert(stats.bytesReceived.count >= 0);
            assert(stats.bytesReceived.distribution.length == 6);
        }
    }
}

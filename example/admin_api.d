import reed.database;

import core.time;

import std.stdio;
import std.conv;
import std.math;

void main()
{
    auto database = new Database();

    writeln("Server version: ", database.serverVersion);
    writeln("Server time: ", database.serverTime);
    writeln("Server role: ", database.serverRole);
    writeln("echo response: ", database.echo());

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

    writeln("Get statictics");

    auto statictics = database.statistics();
    {
        auto status = statictics.system;
        assert(status.userTime > 0.0);
        assert(status.systemTime > 0.0);
        assert(status.numberOfThreads >= 0);
        assert(status.residentSize > 0);
        assert(status.residentSizePercent > 0.0);
        assert(status.virtualSize >= 0);
        assert(status.minorPageFaults >= 0);
        assert(status.majorPageFaults >= 0);
    }

    void checkDistribution(Statistics.ClientInfo.Distribution dist)
    {
        assert(dist.sum >= 0.0);
        assert(dist.count >= 0);
        assert(dist.counts.length > 0);
    }
    {
        auto client = statictics.client;
        assert(client.httpConnections >= 0);
        checkDistribution(client.connectionTime);
        checkDistribution(client.totalTime);
        checkDistribution(client.requestTime);
        checkDistribution(client.queueTime);
        checkDistribution(client.bytesSent);
        checkDistribution(client.bytesReceived);
    }
    {
        auto http = statictics.http;
        assert(http.requestsTotal >= 0);
        assert(http.requestsAsync >= 0);
        assert(http.requestsGet >= 0);
        assert(http.requestsHead >= 0);
        assert(http.requestsPost >= 0);
        assert(http.requestsPut >= 0);
        assert(http.requestsPatch >= 0);
        assert(http.requestsDelete >= 0);
        assert(http.requestsOptions >= 0);
        assert(http.requestsOther >= 0);
    }
    {
        auto server = statictics.server;
        assert(server.uptime > 0.0);
        assert(server.physicalMemory > 0);
    }
}

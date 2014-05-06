import reed.database;

import std.stdio;
import std.conv;
import std.typecons;

struct Data
{
    string name = "shinobu";
    string text = "beautiful";
    ulong age = 20;
    ulong id;
}

void cleanupCollections()
{
    auto database = new Database();
    foreach (collection; database.collections) {
        if (collection.name.front != '_')
            database.deleteCollection(collection.name);
    }
}

void main()
{
    cleanupCollections();

    immutable Num = 10;

    auto database = new Database();

    {
        Data[] dataset;
        foreach (i; 0..Num) {
            Data data;
            data.id = i;
            dataset ~= data;
        }

        auto result = database.bulkImport("test", dataset);
        assert(result.created == Num);
    }

    {
        Tuple!(string, ulong, bool)[] dataset;
        foreach (i; 0..Num) {
            Tuple!(string, ulong, bool) data;
            data[0] = "momoko";
            data[1] = 18;
            data[2] = (i % 2 == 0);
            dataset ~= data;
        }

        auto result = database.bulkImport("test", ["name", "age", "flag"], dataset);
        assert(result.created == Num);
    }

    cleanupCollections();

}

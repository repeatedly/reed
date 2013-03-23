import reed.database;

import std.array;
import std.algorithm;
import std.stdio;

void cleanupCollections()
{
    auto database = new Database();
    foreach (collection; database.collections)
        database.deleteCollection(collection.name);
}

void main()
{
    cleanupCollections();

    auto database = new Database();
    auto collection = database.createCollection(Database.CollectionProperty("sample_collection"));

    void putDocuments()
    {
        import std.conv;

        foreach (i; 0..100)
            collection.putDocument(["class": "a", "id": i.to!string()]);
        foreach (i; 0..100)
            collection.putDocument(["class": "b", "id": i.to!string()]);
        foreach (i; 0..100)
            collection.putDocument(["class": "c", "id": i.to!string()]);
    }

    writeln("Put documents");
    putDocuments();

    {
        writeln("simple/all");
        auto cursor = collection.queryAll();
        {
            size_t i = 0;
            foreach (doc; cursor) i++;
            assert(i == 300);
        }

        writeln("simple/all with 250 skip");
        AllOption option;
        option.skip = 250;
        auto skippedCursor = collection.queryAll(option);
        {
            size_t i = 0;
            foreach (doc; skippedCursor) i++;
            assert(i == 50);
        }

        writeln("simple/all with 250 skip and 10 limit");
        option.limit = 10;
        auto limitedCursor = collection.queryAll!(string[string])(option);
        {
            size_t i = 0;
            foreach (doc; limitedCursor) i++;
            assert(i == 10);
        }
    }

    {
        immutable classes = ["a", "b", "c"];

        writeln("simple/by-example for class");
        foreach (cls; classes) {
            auto result = collection.queryByExample(["class": cls]);
            assert(result.length == 100);
        }

        writeln("simple/by-example for each id");
        foreach (id; 0..100) {
            auto result = collection.queryByExample!(string[string])(["id": id.to!string()]);
            assert(result.length == 3);
            foreach (doc; result)
                assert(!find(classes, doc["class"]).empty);
        }

        writeln("simple/by-example with 90 skip");

        ByExampleOption option;
        option.skip = 90;
        foreach (cls; classes) {
            auto result = collection.queryByExample(["class": cls], option);
            assert(result.length == 10);
        }

        writeln("simple/by-example with 50 skip and 10 limit");
        option.skip = 50;
        option.limit = 20;
        foreach (cls; classes) {
            auto result = collection.queryByExample(["class": cls], option);
            assert(result.length == 20);
        }
    }

    {
        immutable classes = ["a", "b", "c"];

        writeln("simple/first-example for class");
        foreach (cls; classes) {
            auto result = collection.queryFirstExample(["class": cls]);
            assert(result.object["class"].str == cls);
        }
    }

    {
        writeln("simple/any");
        auto result = collection.queryAny();
        assert("class" in result.object);
        assert("id" in result.object);
    }

    cleanupCollections();
}

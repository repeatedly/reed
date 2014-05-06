import reed.database;

import std.array;
import std.algorithm;
import std.stdio;

void cleanupCollections()
{
    auto database = new Database();
    foreach (collection; database.collections) {
        if (collection.name.front != '_')
            database.deleteCollection(collection.name);
    }
}

struct Doc
{
    string type;
    long id;
}

void main()
{
    cleanupCollections();

    auto database = new Database();
    auto collection = database.createCollection(Database.CollectionProperty("sample_collection"));
    auto skiplist = collection.createIndex(SkipListIndexOption(["id"], false));

    void putDocuments()
    {
        import std.conv;

        foreach (i; 0..100)
            collection.putDocument(Doc("a", i));
        foreach (i; 0..100)
            collection.putDocument(Doc("b", i));
        foreach (i; 0..100)
            collection.putDocument(Doc("c", i));
    }

    writeln("Put documents");
    putDocuments();

    {
        writeln("simple/range");
        RangeOption option;
        option.attribute = "id";
        option.left = 10;
        option.right = 20;
        auto cursor = collection.queryRange!Doc(option);
        {
            size_t i;
            foreach (doc; cursor) i++;
            assert(i == 30);
        }

        writeln("simple/range with closed");
        option.left = 70;
        option.right = 90;
        option.closed = true;
        auto closedCursor = collection.queryRange(option);
        {
            size_t i;
            foreach (doc; closedCursor) i++;
            assert(i == 63);
        }
    }

    cleanupCollections();
}

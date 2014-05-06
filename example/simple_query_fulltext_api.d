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
    string text;
    long id;
}

void main()
{
    cleanupCollections();

    auto database = new Database();
    auto collection = database.createCollection(Database.CollectionProperty("fulltext_collection"));
    auto skiplist = collection.createIndex(FulltextIndexOption(["text"]));

    void putDocuments()
    {
        import std.conv;

        foreach (i; 0..100)
            collection.putDocument(Doc("word 0 a", i));
        foreach (i; 0..100)
            collection.putDocument(Doc("1 ward b", i));
        foreach (i; 0..100)
            collection.putDocument(Doc("c word 2", i));
    }

    writeln("Put documents");
    putDocuments();

    writeln("simple/fulltext with word");
    {
        FulltextOption option = FulltextOption("text", "word");
        auto cursor = collection.queryFulltext!Doc(option);
        {
            size_t i;
            foreach (doc; cursor) i++;
            assert(i == 200);
        }
    }

    writeln("simple/fulltext with ward");
    {
        FulltextOption option = FulltextOption("text", "ward");
        auto cursor = collection.queryFulltext!Doc(option);
        {
            size_t i;
            foreach (doc; cursor) i++;
            assert(i == 100);
        }
    }

    writeln("simple/fulltext with unknown");
    {
        FulltextOption option = FulltextOption("text", "unknown");
        assert(collection.queryFulltext!Doc(option).empty);
    }

    cleanupCollections();
}

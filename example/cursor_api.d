import arango.database;

import std.array;
import std.algorithm;
import std.exception;
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

    string query = "FOR u IN sample_collection RETURN u";
    {
        writeln("cursor");
        auto cursor = collection.queryCursor(query);
        {
            size_t i = 0;
            foreach (doc; cursor) i++;
            assert(i == 300);
            assertThrown!Exception(cursor.count);
        }

        writeln("cursor with count");
        CursorOption option;
        option.count = true;
        auto countedCursor = collection.queryCursor(query, option);
        {
            assert(countedCursor.count == 300);
        }

        writeln("cursor with batchSize 10");
        option.batchSize = 10;
        auto batchedCursor = collection.queryCursor(query, option);
        {
            size_t i = 0;
            foreach (doc; batchedCursor) i++;
            assert(i == 300);
        }
    }

    // TODO: Add more AQL examples

    cleanupCollections();
}

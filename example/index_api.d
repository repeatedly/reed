import arango.database;

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
    auto collection = database.createCollection(Database.CollectionProperty("index_test"));
    auto indexes = collection.indexes();
    {
        assert(indexes.length == 1);
        assert(indexes[0].id == text(collection.id, "/", 0));
        assert(indexes[0].type == "primary");
        assert(indexes[0].fields == ["_id"]);
    }

    writeln("Create new indexes");

    auto slOption = SkipListIndexOption(["a"], true);
    auto skiplist = collection.createIndex(slOption);
    {
        assert(skiplist.type == "skiplist");
        assert(skiplist.fields == ["a"]);
        assert(skiplist.unique);
        assert(skiplist.isNewlyCreated);
    }

    auto hash = collection.createIndex(HashIndexOption(["b"], false));
    {
        assert(hash.type == "hash");
        assert(hash.fields == ["b"]);
        assert(!hash.unique);
        assert(hash.isNewlyCreated);
    }

    writeln("Create same index");

    skiplist = collection.createIndex(slOption);
    {
        assert(skiplist.type == "skiplist");
        assert(skiplist.fields == ["a"]);
        assert(skiplist.unique);
        assert(!skiplist.isNewlyCreated);
    }

    writeln("Get indexes");

    indexes = collection.indexes;
    {
        assert(indexes.length == 3);
        foreach (index; indexes.filter!q{a.type != "primary"}) {
            auto got = collection.getIndex(index.id);
            assert(got.id == index.id);
            assert(got.type == index.type);
            assert(got.fields == index.fields);
        }
    } 

    writeln("Delete indexes");
    {
        assert(indexes.length == 3);
        foreach (index; indexes.filter!q{a.type != "primary"}) // "primary" cannot be deleted
            collection.deleteIndex(index.id);
        assert(collection.indexes.length == 1);
    }

    cleanupCollections();
}

import reed.database;

import std.array;
import std.algorithm;
import std.range;
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

    immutable name = "test";
    writeln("Put new document with '", name, "' collection");

    auto database = new Database();
    auto firstDH = database.putDocument(name, ["yes": true]);
    {
        assert(database.collections.length == 1);
        assert(database.collections[0].name == name);
    }

    auto collection = database[name];

    void check(size_t i, DocumentHandle handle)
    {
        switch (i) {
        case 0:
            assert(collection.getDocument!(bool[string])(handle) == ["yes": true]);
            break;
        case 1:
            assert(collection.getDocument!(int[string])(handle) == ["price": 100]);
            break;
        case 2:
            assert(collection.getDocument!(string[string])(handle) == ["name": "shinobu"]);
            break;
        case 3:
            auto config = collection.getDocument!Configuration(handle);
            assert(config.endpoint.host == Configuration().endpoint.host);
            assert(config.endpoint.port == Configuration().endpoint.port);
            break;
        default:
            writeln("Check error");
            return;
        }
    }

    writeln("Put documents");

    DocumentHandle[] handles = [firstDH];
    handles ~= collection.putDocument(["price": 100]);
    handles ~= collection.putDocument(["name": "shinobu"]);
    handles ~= collection.putDocument(Configuration());

    writeln("Get document");

    {
        foreach (i, handle; handles) {
            assert(collection.getDocument(handle).handle == handle);
            check(i, handle);
        }
    }

    writeln("Get URIs");

    auto uris = collection.getDocumentURIs();
    {
        assert(collection.length == uris.length);
        foreach (i, uri; array(sort(uris)))
            check(i, DocumentHandle(uri["/_api/document/".length..$]));
    }

    writeln("Replace document");

    auto replacedDH = collection.replaceDocument(firstDH, ["yes": false, "ok": true]);
    {
        assert(replacedDH.id == firstDH.id);
        assert(replacedDH.revision != firstDH.revision);
        assert(collection.getDocument!(bool[string])(replacedDH) == ["yes": false, "ok": true]);
    }

    writeln("Delete documents");

    {
        foreach (handle; handles)
            collection.deleteDocument(handle);
    }

    assert(collection.length == 0);

    // since ArangoDB 1.2

    writeln("Put document with key");

    auto keyedDH = collection.putDocument(["name": "shinobu"], "myKey");
    assert(keyedDH.id == "test/myKey");
    assert(keyedDH.key == "myKey");

    cleanupCollections();
}

import avocado.database;

import core.thread;
import std.stdio;

void cleanupCollections()
{
    auto database = new Database(Configuration());
    foreach (collection; database.collections)
        database.deleteCollection(collection.name);
}

void main()
{
    cleanupCollections();

    Configuration config;
    auto database = new Database(config);
    {
        assert(database.collections.length == 0);
    }

    immutable name = "test_collection";
    writeln("Create '", name, "' collection");

    Database.CollectionProperty property;
    property.name = name;
    property.waitForSync = true;
    const created = database.createCollection(property);
    {
        assert(created.name == name);
        assert(created.length == 0);
        assert(created.isLoaded);
        assert(created.property.waitForSync);
        assert(database.collections.length == 1);
    }

    writeln("Get '", name, "' collection");

    immutable createdProperty = created.property;
    immutable createdId = created.id;
    auto collection = database[name];
    {
        assert(collection.name == name);
        assert(collection.length == 0);
        assert(collection.id == createdId);
        assert(collection.property == createdProperty);

        const figure = collection.figure;
        assert(figure.alive.count == 0);
        assert(figure.alive.size == 0);
        assert(figure.dead.count == 0);
        assert(figure.dead.size == 0);
        assert(figure.dead.deletion == 0);
        assert(figure.dataFiles.count == 0);
    }

    immutable newName = "renamed_test_collection";
    writeln("Rename '", name, "' to '", newName,"'");

    collection.name = newName;
    auto renamedCollection = database[newName];
    {
        assert(renamedCollection.name != name);
        assert(renamedCollection.name == newName);
        assert(renamedCollection.id == createdId);
    }

    writeln("Unload and Load");

    collection.unload();
    while (database[createdId].isBeingUnloaded) {
        Thread.sleep(dur!("msecs")(500));
        writeln("Now unloading...");
    }
    auto unloadedCollection = database[createdId];
    {
        assert(unloadedCollection.isUnloaded);
    }

    unloadedCollection.load();
    while (!database[createdId].isLoaded)
        writeln("Now loading...");
    auto loadedCollection = database[createdId];
    {
        assert(loadedCollection.isLoaded);
    }

    writeln("Set property");    

    loadedCollection.waitForSync = false;
    immutable changedProperty = loadedCollection.property;
    {
        assert(changedProperty != createdProperty);
        assert(!changedProperty.waitForSync);
    }
    //writeln(typeid(typeof(collections)));
    /*
    string name = "ccc";
    collection.name = name;
    auto collection2 = database["ccc"];
    writeln(collection2.name);
    writeln(collection2.id);

    //collections[0].truncate();
    */
    /*
    */
    cleanupCollections();
}

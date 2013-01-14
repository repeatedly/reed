// Written in the D programming language.

module reed.bulk_import;

import reed.database;
import reed.util;

package
{
    immutable BulkImportAPIPath = buildUriPath(Database.APIPrefix, "import");

    @trusted
    string buildImportPath(in string collectionName, bool create)
    {
        import std.conv : text;

        return text(BulkImportAPIPath, "?collection=", collectionName, "&createCollection=", create);
    }
}

struct BulkImportResult
{
    size_t created;
    size_t errors;
    //size_t empty; // use the number of empty line?
}

mixin template BulkImportAPIs()
{
    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpImport.html#HttpImportSelfContained
     */
    BulkImportResult bulkImport(T)(in string collectionName, auto ref const T[] documents, bool create = true)
    {
        // Whu doesn't work type=array?
        string jsons;
        foreach  (ref document; documents)
            jsons ~= (document.toJSONValue().toJSON() ~ "\n");

        auto path = buildImportPath(collectionName, create) ~ "&type=documents";
        const req = Connection.Request(Method.POST, path, jsons);
        const res = sendRequest(req);

        return fromJSONValue!BulkImportResult(res);
    }

    /**
     * See_Also: http://www.arangodb.org/manuals/current/HttpImport.html#HttpImportHeaderData
     */
    BulkImportResult bulkImport(T)(in string collectionName, in string[] headers, 
                                   auto ref const T[] documents, bool create = true)
    {
        assert(headers.length == T.length, "The headers size is different from the document size");

        string jsons = headers.toJSONValue().toJSON() ~ "\n";
        foreach  (ref document; documents)
            jsons ~= (document.toJSONValue().toJSON() ~ "\n");

        auto path = buildImportPath(collectionName, create);
        const req = Connection.Request(Method.POST, path, jsons);
        const res = sendRequest(req);

        return fromJSONValue!BulkImportResult(res);
    }
}

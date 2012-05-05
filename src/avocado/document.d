// Written in the D programming language.

module avocado.document;

import std.array : split;
import std.conv  : to, text;

import avocado.util;

package
{
    immutable DocumentAPIPath = "document";
}

@trusted
string buildDocumentPath(ref const DocumentHandle handle)
{
    return buildUriPath(DocumentAPIPath, handle.id);
}

struct DocumentHandle
{
    static immutable Separator = "/";

    ulong _rev;
    string _id;

    @trusted
    {
        this(string id)
        {
            _rev = id.split(Separator)[1].to!ulong();
            _id = id;
        }

        this(ulong collectionId, ulong revision)
        {
            _rev = revision;
            _id = text(collectionId, Separator, revision);
        }
    }

    @property @safe nothrow
    {
        ulong revision() const
        {
            return _rev;
        }

        void revision(ulong newRev)
        {
            _rev = newRev;
        }

        string id() const
        {
            return _id;
        }

        void id(string newId)
        {
            _id = newId;
        }
    }
}

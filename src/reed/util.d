// Written in the D programming language.

module reed.util;

import std.array     : array;
import std.algorithm : map, reduce;
import std.conv      : to, text;
import std.json;
import std.range     : ElementType;
import std.traits    : Unqual, isBoolean, isIntegral, isFloatingPoint, isSomeString, isArray, isAssociativeArray, ValueType;
import std.typecons  : Nullable, isTuple;

@safe
string buildUriPath(Paths...)(Paths paths)
{
    static string joinPaths(in string lhs, in string rhs) pure nothrow
    {
        return lhs ~ "/" ~ rhs;
    }

    @trusted
    string[] pathsToStringArray() // TODO: pure nothrow
    {
        auto result = new string[](paths.length);
        foreach (i, path; paths)
            result[i] = path.to!string();
        return result;
    }

    return reduce!joinPaths(pathsToStringArray());
}

unittest
{
    assert(buildUriPath("") == "");
    assert(buildUriPath("handa") == "handa");
    assert(buildUriPath("handa", "shinobu") == "handa/shinobu");
    assert(buildUriPath("handa", 18UL) == "handa/18");
}

@trusted
string joinParameters(in string[string] params)
{
    import std.array : join;
    import std.uri : encode;

    if (params is null)
        return null;

    string[] queries;

    foreach (k, v; params)
        queries ~= k ~ "=" ~ encode(v);
 
    return "?" ~ join(queries, "&");
}

unittest
{
    assert(joinParameters(null) == null);
    assert(joinParameters(["granularity":"days"]) == "?granularity=days");
    assert(joinParameters(["foo":"bar", "hoge":"fuga"]) == "?foo=bar&hoge=fuga");
}

@trusted
{
    string toJSON(const JSONValue value)
    {
        return toJSON(value);
    }

    string toJSON(ref const JSONValue value)
    {
        return std.json.toJSON(&value);
    }
}

@trusted
JSONValue toJSONValue(T)(auto ref T value)
{
    JSONValue result;

    static if (isTuple!T)
    {
        JSONValue[] arr;
        foreach (i, Type; T.Types)
            arr ~= value[i].toJSONValue();
        result = arr;
    }
    else static if (is(T == struct) || is(T == class))
    {
        static if (is(T == class))
        {
            if (value is null) {
                result = null;
                return result;
            }
        }

        JSONValue[string] obj;
        foreach(i, v; value.tupleof) {
            static if (isNullable!(typeof(v)))
            {
                if (!v.isNull)
                    obj[getFieldName!(T, i)] = v.get.toJSONValue();
            }
            else
            {
                obj[getFieldName!(T, i)] = v.toJSONValue();
            }
        }
        result = obj;
    }
    else
    {
        result = value;
    }

    return result;
}

// from msgpack-d
template getFieldName(Type, size_t i)
{
    import std.conv : text;

    static assert((is(Unqual!Type == class) || is(Unqual!Type == struct)), "Type must be class or struct: type = " ~ Type.stringof);
    static assert(i < Type.tupleof.length, text(Type.stringof, " has ", Type.tupleof.length, " attributes: given index = ", i));

    enum getFieldName = __traits(identifier, Type.tupleof[i]);
}

template isNullable(T)
{
    static if (is(Unqual!T U: Nullable!U))
    {
        enum isNullable = true;
    }
    else
    {
        enum isNullable = false;
    }
}

unittest
{
    static assert(isNullable!(Nullable!int));
    static assert(isNullable!(const Nullable!int));
    static assert(isNullable!(immutable Nullable!int));

    static assert(!isNullable!int);
    static assert(!isNullable!(const int));

    struct S {}
    static assert(!isNullable!S);
}

@trusted
T fromJSONValue(T)(ref const JSONValue value)
{
    @trusted
    void typeMismatch(string type)
    {
        throw new JSONException(text("Not ", type,": type = ", value.type));
    }

    T result;

    static if (is(Unqual!T U: Nullable!U))
    {
        result = fromJSONValue!U(value);
    }
    else static if (isBoolean!T)
    {
        if (value.type != JSON_TYPE.TRUE && value.type != JSON_TYPE.FALSE)
            typeMismatch("boolean");
        result = value.type == JSON_TYPE.TRUE;
    }
    else static if (isIntegral!T)
    {
        if (value.type != JSON_TYPE.INTEGER)
            typeMismatch("integer");
        result = value.integer.to!T();
    }
    else static if (isFloatingPoint!T)
    {
        switch (value.type) {
        case JSON_TYPE.FLOAT:
            result = value.floating.to!T();
            break;
        case JSON_TYPE.INTEGER:
            result = value.integer.to!T();
            break;
        case JSON_TYPE.STRING: // for "INF"
            result = value.str.to!T();
            break;
        default:
            typeMismatch("floating point");
        }
    }
    else static if (isSomeString!T)
    {
        if (value.type == JSON_TYPE.NULL)
            return null;
        if (value.type != JSON_TYPE.STRING)
            typeMismatch("string");
        result = value.str.to!T();
    }
    else static if (isArray!T)
    {
        if (value.type != JSON_TYPE.ARRAY)
            typeMismatch("array");
        result = array(map!((a){ return fromJSONValue!(ElementType!T)(a); })(value.array));
    }
    else static if (isAssociativeArray!T)
    {
        if (value.type != JSON_TYPE.OBJECT)
            typeMismatch("object");
        foreach (k, v; value.object)
            result[k] = fromJSONValue!(ValueType!T)(v);
    }
    else static if (is(T == struct) || is(T == class))
    {
        static if (is(T == class))
        {
            if (value.type == JSON_TYPE.NULL)
                return null;
        }

        if (value.type != JSON_TYPE.OBJECT)
            typeMismatch("object");

        static if (is(T == class))
        {
            result = new T();
        }

        foreach(i, ref v; result.tupleof) {
            auto field = getFieldName!(T, i) in value.object;
            if (field)
                v = fromJSONValue!(typeof(v))(*field);
        }
    }

    return result;
}

unittest
{
    {
        JSONValue jtrue = true;
        assert(fromJSONValue!bool(jtrue));
    }
    {
        JSONValue jfalse = false;
        assert(!fromJSONValue!bool(jfalse));
    }
    {
        JSONValue jint = int.max;
        assert(fromJSONValue!int(jint) == int.max);
        assert(fromJSONValue!ulong(jint) == int.max);
    }
    {
        JSONValue jfloat = 10.5f;
        assert(fromJSONValue!double(jfloat) == 10.5f);
        assert(fromJSONValue!real(jfloat) == 10.5f);
    }
    {
        JSONValue jstr = "omoikane";
        assert(fromJSONValue!string(jstr) == "omoikane");
        assert(fromJSONValue!dstring(jstr) == "omoikane"d);
    }
    {
        JSONValue jarr = parseJSON(`[1, 4, 9]`);
        assert(fromJSONValue!(int[])(jarr) == [1, 4, 9]);
        assert(fromJSONValue!(real[])(jarr) == [1f, 4f, 9f]);
    }
    {
        static struct Handa
        {
            static struct AAA
            {
                bool ok;
            }

            ulong id;
            string name;
            double height;
            Nullable!AAA aaa;
        }

        {
            JSONValue jstruct = parseJSON(`{"height":169.5,"id":2,"name":"shinobu","aaa":{"ok":true}}`);
            auto handa = fromJSONValue!Handa(jstruct);
            assert(handa.id == 2);
            assert(handa.name == "shinobu");
            assert(handa.height == 169.5f);
            assert(handa.aaa.ok);
        }
        {
            JSONValue jstruct = parseJSON(`{"height":169.5,"id":2,"name":"shinobu"}`);
            auto handa = fromJSONValue!Handa(jstruct);
            assert(handa.id == 2);
            assert(handa.name == "shinobu");
            assert(handa.height == 169.5f);
            assert(handa.aaa.isNull);
        }
    }
    {
        static class Naito
        {
            ulong id;
            string name;
            double height;
        }

        JSONValue jclass = parseJSON(`{"height":164.0,"id":1,"name":"momoko","other":false}`);
        auto naito = fromJSONValue!Naito(jclass);
        assert(naito.id == 1);
        assert(naito.name == "momoko");
        assert(naito.height == 164.0f);
    }
}

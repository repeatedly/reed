ReeD
================

ArangoDB Driver for D.

ReeD derived from [Avocado varieties](http://ucavo.ucr.edu/avocadovarieties/VarietyList/Reed.html).

# Usage

See example directory.

# Progress (v2.0.x)

## Supported

* API

    * Collections

    * Bulk Imports

    * Documents

        * "etag" header is not supported yet

        * PATCH is not supported yet

    * Index

        * geo is not supported yet

    * AQL Query Cursors

        * TODO: Implement AQL builder

    * Simple Queries

        * near, within, *-by-example, by-example-*, by-condition-* are not supported yet

* Administration

    * Monitoring

    * Miscellaneous functions

## Unsupported yet

* Graph related APIs
* Batch Request APIs
* Async Job (Need to use own HTTP reqeust instead of std.net.curl.post)
* User Management APIs
* Endpoint APIs

# TODO

* Implement APIs (See Progress section)
* Using [yajl-d](https://github.com/repeatedly/yajl-d) or Robert's JSON module

# Link

* [ArangoDB - the universal nosql database](http://www.arangodb.org/)

* [ArangoDB's Github](https://github.com/triAGENS/ArangoDB)

# Copyright

    Copyright (c) 2012- Masahiro Nakagawa

Distributed under the Boost Software License, Version 1.0.

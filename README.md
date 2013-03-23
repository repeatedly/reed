ReeD
================

ArangoDB Driver for D.

ReeD derived from [Avocado varieties](http://ucavo.ucr.edu/avocadovarieties/VarietyList/Reed.html).

# Usage

See example directory.

# TODO

* Implement APIs (See Progress section)
* Using [yajl-d](https://github.com/repeatedly/yajl-d) or Robert's JSON module

# Progress (v1.2.x)

* REST Interface

    * REST Interface for Documents

        * "etag" header is not supported yet.

        * PATCH is not supported yet

    * REST Interface for Edges

* Light-Weight HTTP for Queries and Cursors (Working)

    * <del>HTTP Interface for AQL Query Cursors</del>

        * TODO: Implement AQL builder

    * HTTP Interface for AQL Queries

    * HTTP Interface for Simple Queries

        * <del>all</del>

        * <del>by-example</del>

        * <del>first-example</del>

        * <del>any</del>

        * <del>range</del>

        * near

        * within

        * <del>fulltext</del>

        * remove-by-example

        * replace-by-example

        * update-by-example

* Light-Weight HTTP for Administration

    * <del>HTTP Interface for Collections</del>

    * HTTP Interface for Indexes (80% done)

        * "geo" is not supported yet.

    * <del>HTTP Interface for Administration and Monitoring</del>

    * HTTP Interface for User Management

    * <del>HTTP Interface for Miscellaneous functions</del>

* HTTP Interface for Graphs

* <del>Interface for bulk imports</del>

* Interface for batch operations

# Link

* [ArangoDB - the universal nosql database](http://www.arangodb.org/)

* [ArangoDB's Github](https://github.com/triAGENS/ArangoDB)

# Copyright

    Copyright (c) 2012- Masahiro Nakagawa

Distributed under the Boost Software License, Version 1.0.

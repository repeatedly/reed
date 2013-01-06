ReeD
================

ArangoDB Driver for D.

ReeD derived from [Avocado varieties](http://ucavo.ucr.edu/avocadovarieties/VarietyList/Reed.html).

# Usage

See example directory.

# TODO

* Implement APIs (See Progress section)
* Using Robert's JSON module if compilation succeeded

# Progress (v1.1.x)

* REST Interface

    * <del>REST Interface for Documents</del>

        * "etag" header is not supported yet.

    * REST Interface for Edges

* Light-Weight HTTP for Queries and Cursors (Working)

    * <del>HTTP Interface for AQL Query Cursors</del>

        * TODO: Implement AQL builder

    * HTTP Interface for AQL Queries

    * HTTP Interface for Simple Queries

        * <del>all</del>

        * <del>by-example</del>

        * <del>first-example</del>

        * <del>range</del>

        * near

        * within

* Light-Weight HTTP for Administration

    * <del>HTTP Interface for Collections</del>

    * HTTP Interface for Indexes (60% done)

        * "geo" and "cap" are not supported yet.

    * <del>HTTP Interface for Administration and Monitoring</del>

    * <del>HTTP Interface for Miscellaneous functions</del>

* <del>Interface for bulk imports</del>

* Interface for batch operations

* REST Interface for storing key-value pairs

# Link

* [ArangoDB - the universal nosql database](http://www.arangodb.org/)

* [ArangoDB's Github](https://github.com/triAGENS/ArangoDB)

# Copyright

    Copyright (c) 2012- Masahiro Nakagawa

Distributed under the Boost Software License, Version 1.0.

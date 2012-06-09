Reed
================

ArangoDB Driver for D.

Reed derived from [Avocado varieties](http://ucavo.ucr.edu/avocadovarieties/VarietyList/Reed.html).

# Usage

See example directory.

# TODO

* Implement APIs (See Progress section)
* Using Robert's JSON module if compilation succeeded

# Progress

1. REST Interface

    1. <del>REST Interface for Documents</del>
      * "etag" header is not supported yet.

    2. REST Interface for Edges

2. Light-Weight HTTP for Queries (Working)

    1. HTTP Interface for Cursors (80% done)
      * TODO: Implement AQL builder

    2. HTTP Interface for Simple Queries

3. Light-Weight HTTP for Administration

    1. <del>HTTP Interface for Collections</del>

    2. HTTP Interface for Indexes (60% done)
      * "geo" and "cap" are not supported yet.

    3. HTTP Interface for Administration and Monitoring

    4. Simple Queries

        1. <del>all</del>

        2. <del>by-example</del>

        3. <del>first-example</del>

        4. range

        5. near

        6. within

    5. REST Interface for storing key-value pairs

# Link

* [ArangoDB - the universal nosql database](http://www.arangodb.org/)

* [ArangoDB's Github](https://github.com/triAGENS/AvocadoDB)

# Copyright

    Copyright (c) 2012- Masahiro Nakagawa

Distributed under the Boost Software License, Version 1.0.

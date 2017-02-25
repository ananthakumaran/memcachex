# Change Log

## [Unreleased]

## [0.3.0] - 26 Feb 2017

### New
- add support for multi set & get

### Breaking
- changed the returned type of stat from HashDict to map
- dropped support for 1.1

## [0.2.1] - 25 July 2016

### New
- coder

## [0.2.0] - 23 July 2016

### New
- Plain auth.
- namespace and default ttl

### Breaking
- pid can't be used interchangeably between Memcache and
  Memcache.Connection
- Removed Memcache.execute. Get connection pid using
  Memcache.connection_pid and interact with the Memcache.Connection
  directly.



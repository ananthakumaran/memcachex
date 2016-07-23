# Change Log

## [Unreleased]

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



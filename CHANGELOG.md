# Change Log

## [Unreleased]

### New
- Uses a separate process to read response from the server. This would
  lead to increased throughput if same connection was accessed from
  different process concurrently.

### Breaking
- Removed Memcache.connection_pid. It was a mistake to expose the
  underlying connection id, as it creates problems for future
  additions like pool and cluster.

## [0.3.0] - 25 Feb 2017

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



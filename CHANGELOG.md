# Change Log

## [Unreleased]
- child_spec
- fix warnings and format code

## [0.4.2] - 14 Sep 2017

- add support for dynamic namespace [#6]
- update poison version [#9]

## [0.4.1] - 1 April 2017

- bug fix

## [0.4.0] - 20 Mar 2017

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



# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.7] - 1 July 2024

- add SSL support
- support poison 6.x

## [0.5.6] - 23 April 2024

- support poison 5.x

## [0.5.5] - 1 November 2022

- add ttl and default option in cas/4 [#29]  [#31]

## [0.5.4] - 26 Dec 2021

- relax connection version

## [0.5.3] - 26 Dec 2021

- fix warnings on elixir 1.13

## [0.5.2] - 28 Sep 2021

- relax telemetry version [#26]

## [0.5.1] - 24 April 2021

- add connect_timeout option [#24]

## [0.5.0] - 10 Dec 2019

- add telemetry support [#23]

## [0.4.6] - 8 Aug 2019

- fix dialyzer spec [#20]

## [0.4.3] - 26 Sep 2017

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

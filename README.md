# Memcachex

[![Build Status](https://secure.travis-ci.org/ananthakumaran/memcachex.png)](http://travis-ci.org/ananthakumaran/memcachex)

Memcached client for Elixir

## Installation

```elixir
defp deps() do
  ...
  {:memcachex, "~> 0.2.1"},
  ...
end

defp application() do
  [applications: [:logger, :memcachex, ...]]
end
```

Config with default values:

```elixir
config :memcachex,
  # connection options
  hostname: "localhost",
  port: 11211,
  backoff_initial: 500,
  backoff_max: 30_000,
  # memcached options
  ttl: 0,
  namespace: nil,
  coder: {Memcache.Coder.Raw, []},
  # connection pool options
  strategy: :lifo,
  size: 10,
  max_overflow: 10
```

## Overview

Memcachex comes with two kinds of API, a high level one named
`Memcachex` which provides functions to perform most of the common
usecases and a low level one named `Memcache.Connection` which
provides a less restrictive API. See the
[documentation](https://hexdocs.pm/memcachex) for more information

## Example

```elixir
iex> Memcachex.set("hello", "world")
{:ok}
iex> Memcachex.get("hello")
{:ok, "world"}
```

See test folder for further examples.

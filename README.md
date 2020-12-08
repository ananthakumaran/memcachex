# Memcache

[![Hex.pm](https://img.shields.io/hexpm/v/memcachex.svg)](https://hex.pm/packages/memcachex)

Memcached client for Elixir

## Installation

```elixir
defp deps() do
  [{:memcachex, "~> 0.4"}]
end
```

## Overview

Memcachex comes with two kinds of API, a high level one named
`Memcache` which provides functions to perform most of the common
usecases and a low level one named `Memcache.Connection` which
provides a less restrictive API. See the
[documentation](https://hexdocs.pm/memcachex) for more information

## Example

```elixir
{:ok, pid} = Memcache.start_link()
{:ok} = Memcache.set(pid, "hello", "world")
{:ok, "world"} = Memcache.get(pid, "hello")
```

See test folder for further examples.

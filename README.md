# Memcache

[![CI](https://github.com/ananthakumaran/memcachex/actions/workflows/ci.yml/badge.svg)](https://github.com/ananthakumaran/memcachex/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/memcachex.svg)](https://hex.pm/packages/memcachex)
[![Module Version](https://img.shields.io/hexpm/v/memcachex.svg)](https://hex.pm/packages/memcachex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/memcachex/)
[![Total Download](https://img.shields.io/hexpm/dt/memcachex.svg)](https://hex.pm/packages/memcachex)
[![License](https://img.shields.io/hexpm/l/memcachex.svg)](https://github.com/ananthakumaran/memcachex/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/ananthakumaran/memcachex.svg)](https://github.com/ananthakumaran/memcachex/commits/master)

Memcached client for Elixir.

## Installation

```elixir
defp deps() do
  [
    {:memcachex, "~> 0.5.2"}
  ]
end
```

## Overview

Memcachex comes with two kinds of API, a high level one named
`Memcache` which provides functions to perform most of the common
usecases and a low level one named `Memcache.Connection` which
provides a less restrictive API. See the
[documentation](https://hexdocs.pm/memcachex) for more information

## Examples

```elixir
{:ok, pid} = Memcache.start_link()
{:ok} = Memcache.set(pid, "hello", "world")
{:ok, "world"} = Memcache.get(pid, "hello")
```

See [test folder](https://github.com/ananthakumaran/memcachex/tree/master/test) for further examples.

## Copyright and License

Copyright (c) 2014 Anantha Kumaran

This software is licensed under [the MIT license](./LICENSE.md).

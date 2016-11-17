# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Here below is a sample configuration with default values

config :memcachex,
  # Connection options. See Memcache.Connection docs.
  hostname: "localhost",
  port: 11211,
  backoff_initial: 500,
  backoff_max: 30_000,
  auth: nil,
  # Memcache options
  ttl: 0,
  namespace: nil,
  coder: {Memcache.Coder.Raw, []},
  pool_size: 10,
  pool_max_overflow: 20

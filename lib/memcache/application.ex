defmodule Memcache.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Memcache.Registry
    ]

    opts = [strategy: :one_for_one, name: Memcache.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

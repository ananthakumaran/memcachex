defmodule Memcachex do
  @moduledoc """
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Memcache.Pool, [], [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

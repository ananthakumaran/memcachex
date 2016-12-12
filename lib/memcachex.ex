defmodule Memcachex do
  @moduledoc """
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    config_opts = Application.get_all_env(:memcachex)
    config_opts = Keyword.drop(config_opts, [:included_applications])

    children = [
      worker(Memcache.Pool, [config_opts], [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

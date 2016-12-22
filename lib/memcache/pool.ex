defmodule Memcache.Pool do
  @moduledoc """
  Module that creates a pool of connections to the memcached server using
  poolboy
  """

  use Memcache.Api

  @default_opts [
    strategy: :lifo,
    size: 10,
    max_overflow: 10
  ]

  @doc """
  Creates a pool of connections supervised by poolboy.

  ## Connection Options

  This is a superset of the connection options accepted by the
  `Memcache.Worker.start_link/1`. The following list specifies the
  additional options.

  * `:strategy` - (atom) :fifo or :lifo. Determines whether checked in workers
    should be placed first or last in the line of available workers.

  * `:size` - (integer) the number of connections of the pool.

  * `:max_overflow` - (integer) maximum number of workers created
    if pool is empty.

  * `:name` - Name of the pool.
  """
  def start_link(conn_opts \\ []) do
    name_opt = name_opts(conn_opts)
    extra_opts = [:strategy, :size, :max_overflow]
    pool_opts = Keyword.take(conn_opts, extra_opts)
    pool_opts = Keyword.merge(@default_opts, pool_opts)
      |> Keyword.put(:worker_module, Memcache.Worker)
    conn_opts = Keyword.drop(conn_opts, Keyword.keys(pool_opts))

    :poolboy.start_link(pool_opts ++ name_opt, conn_opts)
  end

  def close(pool) do
    {:poolboy.stop(pool)}
  end

  def connection_pid(pool) do
    :poolboy.transaction(pool, fn(pid) ->
      connection_pid(pid)
    end)
  end

  def execute_k(pool, command, args, opts \\ []) do
    :poolboy.transaction(pool, fn(pid) ->
      apply(Memcache.Worker, :execute_k, [pid, command, args, opts])
    end)
  end

  def execute_kv(pool, command, args, opts) do
    :poolboy.transaction(pool, fn(pid) ->
      apply(Memcache.Worker, :execute_kv, [pid, command, args, opts])
    end)
  end

  def execute(pool, command, args, opts \\ []) do
    :poolboy.transaction(pool, fn(pid) ->
      apply(Memcache.Worker, :execute, [pid, command, args, opts])
    end)
  end

  ## Helpers

  defp name_opts(opts) do
    case Keyword.get(opts, :name) do
      nil                     -> []
      name when is_atom(name) -> [name: {:local, name}]
      name                    -> [name: name]
    end
  end

end

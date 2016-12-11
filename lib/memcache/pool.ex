defmodule Memcache.Pool do
  @moduledoc """

  ## Options

  * `:strategy` - (atom) :fifo or :lifo. Determines whether checked in workers
    should be placed first or last in the line of available workers.
  * `:size` - (integer) the number of connections of the pool.
  * `:max_overflow` - (integer) maximum number of workers created
    if pool is empty.
  * `:name` -
  """
  use Memcache.Api

  @default_opts [
    strategy: :lifo,
    size: 10,
    max_overflow: 10
  ]

  def start_link(conn_opts \\ [], opts \\ []) do
    name_opt = name_opts(opts)
    pool_opts =
      Keyword.merge(@default_opts, opts)
      |> Keyword.drop([:name])
      |> Keyword.put(:worker_module, Memcache.Worker)
      
    :poolboy.start_link(pool_opts ++ name_opt, conn_opts)
  end

  # def child_spec(conn_opts, opts, child_opts) do
  #   {pool_opts, worker_args} = pool_args(conn_opts, opts)
  #   id = Keyword.get(child_opts, :id, __MODULE__)
  #   :poolboy.child_spec(id, pool_opts, worker_args)
  # end

  def stop(pool) do
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

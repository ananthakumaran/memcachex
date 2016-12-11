defmodule Memcache.Pool do
  @moduledoc """

  ## Options

  * `:strategy` - (atom) :lifo or :fifo
  * `:size` - (integer)
  * `:max_overflow` - (integer)
  * `:name` -
  """
  use Memcache.Api

  @default_opts [
    strategy: :lifo,
    size: 10,
    max_overflow: 10
  ]

  def start_link(conn_opts \\ [], opts \\ []) do
    pool_opts =
      Keyword.merge(@default_opts, opts)
      |> Keyword.update(:name, [], &name_opt/1)
      |> Keyword.put(:worker_module, Memcache.Worker)
    :poolboy.start_link(pool_opts, conn_opts)
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

  defp name_opt(name) do
    case name do
      nil                     -> nil
      name when is_atom(name) -> {:local, name}
      name                    -> name
    end
  end

end

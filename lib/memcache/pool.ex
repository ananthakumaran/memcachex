defmodule Memcache.Pool do
  @moduledoc """

  ## Options

  * `:pool_strategy` - (atom) :lifo or :fifo
  * `:pool_size` - (integer)
  * `:pool_overflow` - (integer)
  * `:name` -
  """
  use GenServer
  use Memcache.Api

  def start_link(conn_opts \\ [], opts \\ []) do
    {pool_opts, worker_args} = pool_args(conn_opts, opts)
    {:ok, pool} = :poolboy.start_link(pool_opts, worker_args)
    conn_opts = conn_opts |> Keyword.put(:pool, pool)
    GenServer.start_link(__MODULE__, conn_opts, opts)
  end

  def init(opts) do
    {:ok, opts |> Enum.into(%{})}
  end

  def child_spec(conn_opts, opts, child_opts) do
    {pool_opts, worker_args} = pool_args(conn_opts, opts)
    id = Keyword.get(child_opts, :id, __MODULE__)
    :poolboy.child_spec(id, pool_opts, worker_args)
  end

  ## Helpers

  defp pool_args(conn_opts, opts) do
    pool_opts = [strategy: Keyword.get(opts, :pool_strategy, :fifo),
                 size: Keyword.get(opts, :pool_size, 10),
                 max_overflow: Keyword.get(opts, :pool_overflow, 10),
                 worker_module: Memcache.Worker]
    {name_opts(opts) ++ pool_opts, conn_opts}
  end

  defp name_opts(opts) do
    case Keyword.get(opts, :name) do
      nil                     -> []
      name when is_atom(name) -> [name: {:local, name}]
      name                    -> [name: name]
    end
  end

  def handle_call({:execute, command, args}, _from, state) do
    pool = Map.get(state, :pool)
    result = :poolboy.transaction(pool, fn(pid) ->
      apply(Memcache.Worker, command, [pid] ++ args)
    end)
    {:reply, result, state}
  end

end

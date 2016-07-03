defmodule Memcache do
  alias Memcache.Connection

  defdelegate start_link(), to: Connection
  defdelegate start_link(connection_opts), to: Connection
  defdelegate start_link(connection_opts, process_opts), to: Connection

  defdelegate stop(connection), to: Connection, as: :close

  defdelegate execute(connection, command, args), to: Connection
  defdelegate execute(connection, command, args, opts), to: Connection

  def get(connection, key, opts \\ []) do
    execute(connection, :GET, [key], opts)
  end

  def set(connection, key, value, opts \\ []) do
    execute(connection, :SET, [key, value], opts)
  end

  def set_cas(connection, key, value, cas, opts \\ []) do
    execute(connection, :SET, [key, value, cas], opts)
  end

  def add(connection, key, value, opts \\ []) do
    execute(connection, :ADD, [key, value], opts)
  end

  def replace(connection, key, value, opts \\ []) do
    execute(connection, :REPLACE, [key, value], opts)
  end

  def replace_cas(connection, key, value, cas, opts \\ []) do
    execute(connection, :REPLACE, [key, value, cas], opts)
  end

  def delete(connection, key) do
    execute(connection, :DELETE, [key])
  end

  def delete_cas(connection, key, cas) do
    execute(connection, :DELETE, [key, cas])
  end

  def flush(connection) do
    execute(connection, :FLUSH, [])
  end

  def append(connection, key, value, opts \\ []) do
    execute(connection, :APPEND, [key, value], opts)
  end

  def append_cas(connection, key, value, cas, opts \\ []) do
    execute(connection, :APPEND, [key, value, cas], opts)
  end

  def prepend(connection, key, value, opts \\ []) do
    execute(connection, :PREPEND, [key, value], opts)
  end

  def prepend_cas(connection, key, value, cas, opts \\ []) do
    execute(connection, :PREPEND, [key, value, cas], opts)
  end

  def incr(connection, key, opts \\ []) do
    incr_cas(connection, key, 0, opts)
  end

  def incr_cas(connection, key, cas, opts \\ []) do
    defaults = [by: 1, default: 0]
    opts = Keyword.merge(defaults, opts)
    execute(connection, :INCREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas], opts)
  end

  def decr(connection, key, opts \\ []) do
    decr_cas(connection, key, 0, opts)
  end

  def decr_cas(connection, key, cas, opts \\ []) do
    defaults = [by: 1, default: 0]
    opts = Keyword.merge(defaults, opts)
    execute(connection, :DECREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas], opts)
  end

  def stat(connection) do
    execute(connection, :STAT, [])
  end

  def stat(connection, key) do
    execute(connection, :STAT, [key])
  end

  def version(connection) do
    execute(connection, :VERSION, [])
  end

  def noop(connection) do
    execute(connection, :NOOP, [])
  end

end

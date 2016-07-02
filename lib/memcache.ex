defmodule Memcache do
  alias Memcache.Connection

  defdelegate start_link(), to: Connection
  defdelegate start_link(connection_opts), to: Connection
  defdelegate start_link(connection_opts, process_opts), to: Connection

  defdelegate stop(connection), to: Connection, as: :close

  defdelegate execute(connection, command, args), to: Connection

  def get(connection, key) do
    execute(connection, :GET, [key])
  end

  def set(connection, key, value) do
    execute(connection, :SET, [key, value])
  end

  def add(connection, key, value) do
    execute(connection, :ADD, [key, value])
  end

  def replace(connection, key, value) do
    execute(connection, :REPLACE, [key, value])
  end

  def delete(connection, key) do
    execute(connection, :DELETE, [key])
  end

  def flush(connection) do
    execute(connection, :FLUSH, [])
  end

  def append(connection, key, value) do
    execute(connection, :APPEND, [key, value])
  end

  def prepend(connection, key, value) do
    execute(connection, :PREPEND, [key, value])
  end

  def incr(connection, key, opts \\ []) do
    defaults = [by: 1, default: 0]
    opts = Keyword.merge(defaults, opts)
    execute(connection, :INCREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default)])
  end

  def decr(connection, key, opts \\ []) do
    defaults = [by: 1, default: 0]
    opts = Keyword.merge(defaults, opts)
    execute(connection, :DECREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default)])
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

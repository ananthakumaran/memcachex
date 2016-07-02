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

  def delete(connection, key) do
    execute(connection, :DELETE, [key])
  end

  def flush(connection) do
    execute(connection, :FLUSH, [])
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

defmodule Memcache do
  alias Memcache.Connection

  defdelegate start_link(), to: Connection
  defdelegate start_link(connection_opts), to: Connection
  defdelegate start_link(connection_opts, process_opts), to: Connection

  defdelegate stop(connection), to: Connection, as: :close

  def get(connection, key) do
    Connection.execute(connection, :GET, [key])
  end

  def set(connection, key, value) do
    Connection.execute(connection, :SET, [key, value])
  end
end

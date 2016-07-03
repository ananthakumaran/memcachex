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
    set_cas(connection, key, value, 0, opts)
  end

  def set_cas(connection, key, value, cas, opts \\ []) do
    execute(connection, :SET, [key, value, cas, Keyword.get(opts, :ttl, 0)], opts)
  end

  @cas_error { :error, "Key exists" }

  def cas(connection, key, update, opts \\ []) do
    case get(connection, key, [cas: true]) do
      { :ok, value, cas } ->
        case set_cas(connection, key, update.(value), cas) do
          @cas_error ->
            if Keyword.get(opts, :retry, true) do
              cas(connection, key, update)
            else
              @cas_error
            end
          result -> result
        end
      err -> err
    end
  end

  def add(connection, key, value, opts \\ []) do
    execute(connection, :ADD, [key, value, Keyword.get(opts, :ttl, 0)], opts)
  end

  def replace(connection, key, value, opts \\ []) do
    replace_cas(connection, key, value, 0, opts)
  end

  def replace_cas(connection, key, value, cas, opts \\ []) do
    execute(connection, :REPLACE, [key, value, cas, Keyword.get(opts, :ttl, 0)], opts)
  end

  def delete(connection, key) do
    execute(connection, :DELETE, [key])
  end

  def delete_cas(connection, key, cas) do
    execute(connection, :DELETE, [key, cas])
  end

  def flush(connection, opts \\ []) do
    execute(connection, :FLUSH, [Keyword.get(opts, :ttl, 0)])
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
    execute(connection, :INCREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas, Keyword.get(opts, :ttl, 0)], opts)
  end

  def decr(connection, key, opts \\ []) do
    decr_cas(connection, key, 0, opts)
  end

  def decr_cas(connection, key, cas, opts \\ []) do
    defaults = [by: 1, default: 0]
    opts = Keyword.merge(defaults, opts)
    execute(connection, :DECREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas, Keyword.get(opts, :ttl, 0)], opts)
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

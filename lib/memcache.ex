defmodule Memcache do
  @moduledoc """
  This module provides a user friendly API to interact with the
  memcached server.

  ## Example

      { :ok, pid } = Memcache.start_link()
      { :ok } = Memcache.set(pid, "hello", "world")
      { :ok, "world" } = Memcache.get(pid, "hello")


  ## Coder

  `Memcache.Coder` allows you to specify how the value should be encoded before
  sending it to the server and how it should be decoded after it is
  retrived. There are four built-in coders namely `Memcache.Coder.Raw`,
  `Memcache.Coder.Erlang`, `Memcache.Coder.JSON`,
  `Memcache.Coder.ZIP`. Custom coders can be created by implementing
  the `Memcache.Coder` behaviour.

  ## CAS

  CAS feature allows to atomically perform two commands on a key. Get
  the cas version number associated with a key during the first
  command and pass that value during the second command. The second
  command will fail if the value has changed by someone else in the
  mean time.

      {:ok, "hello", cas} = Memcache.get(pid, "key", cas: true)
      {:ok} = Memcache.set_cas(pid, "key", "world", cas)

  Memcache module provides a *_cas variant for most of the
  functions. This function will take an additional argument named
  `cas` and returns the same value as their counterpart except in case
  of CAS error. In case of CAS error the returned value would be equal
  to `{ :error, "Key exists" }`

  ## Options

  Most the functions in this module accept an optional `Keyword`
  list. The below list specifies the behavior of each option. The list
  of option accepted by a specific function will be documented in the
  specific funcion.

  * `:cas` - (boolean) returns the CAS value associated with the
    data. This value will be either in second or third position
    of the returned tuple depending on the command. Defaults to `false`.

  * `:ttl` - (integer) specifies the expiration time in seconds for
    the corresponding key. Can be set to `0` to disable
    expiration. The Default value can be configured using
    `start_link/2`.
  """

  @type error :: {:error, binary | atom}
  @type result ::
  {:ok} | {:ok, integer} |
  {:ok, any} | {:ok, any, integer} |
  error

  @type fetch_result ::
  {:ok, any} | {:ok, any, integer} |
  error

  @type fetch_integer_result ::
  {:ok, integer} | {:ok, integer, integer} |
  error

  @type store_result ::
  {:ok} | {:ok, integer} |
  error

  alias Memcache.Connection

  @default_opts [
    ttl: 0,
    namespace: nil,
    coder: {Memcache.Coder.Raw, []}
  ]

  @doc """
  Creates a connection using `Memcache.Connection.start_link/2`

  ## Connection Options

  This is a superset of the connection options accepted by the
  `Memcache.Connection.start_link/2`. The following list specifies the
  additional options.

  * `:ttl` - (integer) a default expiration time in seconds. This
    value will be used if the `:ttl` value is not specified for a
    operation. Defaults to `0`(means forever).

  * `:namespace` - (string) prepend each key with the given
    value.

  * `:coder` - (module | {module, options}) Can be either a module or
    tuple contains the module and options. Defaults to
    `{Memcache.Coder.Raw, []}`.

  ## Options

  The second option is passed directly to the underlying
  `GenServer.start_link/3`, so it can be used to create named process.
  """
  @spec start_link(Keyword.t, Keyword.t) :: GenServer.on_start
  def start_link(connection_options \\ [], options \\ []) do
    extra_opts = [:ttl, :namespace, :coder]
    connection_options = Keyword.merge(@default_opts, connection_options)
    |> Keyword.update!(:coder, &normalize_coder/1)
    state = connection_options |> Keyword.take(extra_opts) |> Enum.into(%{})
    Agent.start_link(fn ->
      {:ok, pid} = Connection.start_link(Keyword.drop(connection_options, extra_opts), options)
      Map.put(state, :connection, pid)
    end, options)
  end

  @doc """
  Closes the connection to the memcached server.
  """
  @spec stop(GenServer.server) :: {:ok}
  def stop(server) do
    result = Connection.close(connection(server))
    :ok = Agent.stop(server)
    result
  end

  @doc """
  Gets the value associated with the key. Returns `{:error, "Key not
  found"}` if the given key doesn't exist.

  Accepted option: `:cas`
  """
  @spec get(GenServer.server, binary, Keyword.t) :: fetch_result
  def get(server, key, opts \\ []) do
    execute_k(server, :GET, [key], opts)
  end


  @doc """
  Gets the values associated with the list of keys. Returns a
  map. Keys that are not found in the server are filtered from the
  result.

  Accepted option: `:cas`
  """
  @spec multi_get(GenServer.server, [binary], Keyword.t) :: {:ok, map} | error
  def multi_get(server, keys, opts \\ []) do
    commands = Enum.map(keys, &({:GETQ, [&1], opts}))
    with {:ok, values} <- execute_quiet_k(server, commands) do
      result = Enum.zip(keys, values)
      |> Enum.reduce(%{}, fn
        ({key, {:ok, value}}, acc) -> Map.put(acc, key, value)
        ({key, {:ok, value, cas}}, acc) -> Map.put(acc, key, {value, cas})
        ({_key, {:error, _}}, acc) -> acc
      end)
      {:ok, result}
    end
  end

  @doc """
  Sets the key to value

  Accepted options: `:cas`, `:ttl`
  """
  @spec set(GenServer.server, binary, binary, Keyword.t) :: store_result
  def set(server, key, value, opts \\ []) do
    set_cas(server, key, value, 0, opts)
  end

  @doc """
  Sets the key to value if the key exists and has CAS value equal to
  the provided value

  Accepted options: `:cas`, `:ttl`
  """
  @spec set_cas(GenServer.server, binary, binary, integer, Keyword.t) :: store_result
  def set_cas(server, key, value, cas, opts \\ []) do
    execute_kv(server, :SET, [key, value, cas, ttl_or_default(server, opts)], opts)
  end

  @doc """
  Multi version of `set/4`. Accepts a map or a list of `{key, value}`.

  Accepted options: `:cas`, `:ttl`
  """
  @spec multi_set(GenServer.server, [{binary, binary}] | map, Keyword.t) :: {:ok, [store_result]} | error
  def multi_set(server, commands, opts \\ []) do
    commands = Enum.map(commands, fn {key, value} -> {key, value, 0} end)
    multi_set_cas(server, commands, opts)
  end

  @doc """
  Multi version of `set_cas/4`. Accepts a list of `{key, value, cas}`.

  Accepted options: `:cas`, `:ttl`
  """
  @spec multi_set_cas(GenServer.server, [{binary, binary, integer}], Keyword.t) :: {:ok, [store_result]} | error
  def multi_set_cas(server, commands, opts \\ []) do
    op = if Keyword.get(opts, :cas, false), do: :SET, else: :SETQ
    commands = Enum.map(commands, fn {key, value, cas} -> {op, [key, value, cas, ttl_or_default(server, opts)], opts} end)
    execute_quiet_kv(server, commands)
  end

  @cas_error { :error, "Key exists" }

  @doc """
  Compare and swap value using optimistic locking.

  1. Get the existing value for key
  2. If it exists, call the update function with the value
  3. Set the returned value for key

  The 3rd operation will fail if someone else has updated the value
  for the same key in the mean time. In that case, by default, this
  function will go to step 1 and try again. Retry behavior can be
  disabled by passing `[retry: false]` option.
  """
  @spec cas(GenServer.server, binary, (binary -> binary), Keyword.t) :: {:ok, any} | error
  def cas(server, key, update, opts \\ []) do
    case get(server, key, [cas: true]) do
      { :ok, value, cas } ->
        new_value = update.(value)
        case set_cas(server, key, new_value, cas) do
          @cas_error ->
            if Keyword.get(opts, :retry, true) do
              cas(server, key, update)
            else
              @cas_error
            end
          { :error, _ } = other_errors -> other_errors
          { :ok } -> { :ok, new_value }
        end
      err -> err
    end
  end

  @doc """
  Sets the key to value if the key doesn't exist already. Returns
  `{:error, "Key exists"}` if the given key already exists.

  Accepted options: `:cas`, `:ttl`
  """
  @spec add(GenServer.server, binary, binary, Keyword.t) :: store_result
  def add(server, key, value, opts \\ []) do
    execute_kv(server, :ADD, [key, value, ttl_or_default(server, opts)], opts)
  end

  @doc """
  Sets the key to value if the key already exists. Returns `{:error,
  "Key not found"}` if the given key doesn't exist.

  Accepted options: `:cas`, `:ttl`
  """
  @spec replace(GenServer.server, binary, binary, Keyword.t) :: store_result
  def replace(server, key, value, opts \\ []) do
    replace_cas(server, key, value, 0, opts)
  end

  @doc """
  Sets the key to value if the key already exists and has CAS value
  equal to the provided value.

  Accepted options: `:cas`, `:ttl`
  """
  @spec replace_cas(GenServer.server, binary, binary, integer, Keyword.t) :: store_result
  def replace_cas(server, key, value, cas, opts \\ []) do
    execute_kv(server, :REPLACE, [key, value, cas, ttl_or_default(server, opts)], opts)
  end

  @doc """
  Removes the item with the given key value. Returns `{ :error, "Key
  not found" }` if the given key is not found
  """
  @spec delete(GenServer.server, binary) :: store_result
  def delete(server, key) do
    execute_k(server, :DELETE, [key])
  end

  @doc """
  Removes the item with the given key value if the CAS value is equal
  to the provided value
  """
  @spec delete_cas(GenServer.server, binary, integer) :: store_result
  def delete_cas(server, key, cas) do
    execute_k(server, :DELETE, [key, cas])
  end

  @doc """
  Flush all the items in the server. `ttl` option will cause the flush
  to be delayed by the specified time.

  Accepted options: `:ttl`
  """
  @spec flush(GenServer.server, Keyword.t) :: store_result
  def flush(server, opts \\ []) do
    execute(server, :FLUSH, [Keyword.get(opts, :ttl, 0)])
  end

  @doc """
  Appends the value to the end of the current value of the
  key. Returns `{:error, "Item not stored"}` if the item is not present
  in the server already

  Accepted options: `:cas`
  """
  @spec append(GenServer.server, binary, binary, Keyword.t) :: store_result
  def append(server, key, value, opts \\ []) do
    execute_kv(server, :APPEND, [key, value], opts)
  end

  @doc """
  Appends the value to the end of the current value of the
  key if the CAS value is equal to the provided value

  Accepted options: `:cas`
  """
  @spec append_cas(GenServer.server, binary, binary, integer, Keyword.t) :: store_result
  def append_cas(server, key, value, cas, opts \\ []) do
    execute_kv(server, :APPEND, [key, value, cas], opts)
  end

  @doc """
  Prepends the value to the start of the current value of the
  key. Returns `{:error, "Item not stored"}` if the item is not present
  in the server already

  Accepted options: `:cas`
  """
  @spec prepend(GenServer.server, binary, binary, Keyword.t) :: store_result
  def prepend(server, key, value, opts \\ []) do
    execute_kv(server, :PREPEND, [key, value], opts)
  end

  @doc """
  Prepends the value to the start of the current value of the
  key if the CAS value is equal to the provided value

  Accepted options: `:cas`
  """
  @spec prepend_cas(GenServer.server, binary, binary, integer, Keyword.t) :: store_result
  def prepend_cas(server, key, value, cas, opts \\ []) do
    execute_kv(server, :PREPEND, [key, value, cas], opts)
  end

  @doc """
  Increments the current value. Only integer value can be
  incremented. Returns `{ :error, "Incr/Decr on non-numeric value"}` if
  the value stored in the server is not numeric.

  ## Options

  * `:by` - (integer) The amount to add to the existing
    value. Defaults to `1`.

  * `:default` - (integer) Default value to use in case the key is not
    found. Defaults to `0`.

  other options: `:cas`, `:ttl`
  """
  @spec incr(GenServer.server, binary, Keyword.t) :: fetch_integer_result
  def incr(server, key, opts \\ []) do
    incr_cas(server, key, 0, opts)
  end

  @doc """
  Increments the current value if the CAS value is equal to the
  provided value.

  ## Options

  * `:by` - (integer) The amount to add to the existing
    value. Defaults to `1`.

  * `:default` - (integer) Default value to use in case the key is not
    found. Defaults to `0`.

  other options: `:cas`, `:ttl`
  """
  @spec incr_cas(GenServer.server, binary, integer, Keyword.t) :: fetch_integer_result
  def incr_cas(server, key, cas, opts \\ []) do
    defaults = [by: 1, default: 0]
    opts = Keyword.merge(defaults, opts)
    execute_k(server, :INCREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas, ttl_or_default(server, opts)], opts)
  end

  @doc """
  Decremens the current value. Only integer value can be
  decremented. Returns `{ :error, "Incr/Decr on non-numeric value"}` if
  the value stored in the server is not numeric.

  ## Options

  * `:by` - (integer) The amount to add to the existing
    value. Defaults to `1`.

  * `:default` - (integer) Default value to use in case the key is not
    found. Defaults to `0`.

  other options: `:cas`, `:ttl`
  """
  @spec decr(GenServer.server, binary, Keyword.t) :: fetch_integer_result
  def decr(server, key, opts \\ []) do
    decr_cas(server, key, 0, opts)
  end

  @doc """
  Decrements the current value if the CAS value is equal to the
  provided value.

  ## Options

  * `:by` - (integer) The amount to add to the existing
    value. Defaults to `1`.

  * `:default` - (integer) Default value to use in case the key is not
    found. Defaults to `0`.

  other options: `:cas`, `:ttl`
  """
  @spec decr_cas(GenServer.server, binary, integer, Keyword.t) :: fetch_integer_result
  def decr_cas(server, key, cas, opts \\ []) do
    defaults = [by: 1, default: 0]
    opts = Keyword.merge(defaults, opts)
    execute_k(server, :DECREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas, ttl_or_default(server, opts)], opts)
  end

  @doc """
  Gets the default set of server statistics
  """
  @spec stat(GenServer.server) :: {:ok, map} | error
  def stat(server) do
    execute(server, :STAT, [])
  end

  @doc """
  Gets the specific set of server statistics
  """
  @spec stat(GenServer.server, String.t) :: {:ok, map} | error
  def stat(server, key) do
    execute(server, :STAT, [key])
  end

  @doc """
  Gets the version of the server
  """
  @spec version(GenServer.server) :: String.t | error
  def version(server) do
    execute(server, :VERSION, [])
  end

  @doc """
  Sends a noop command
  """
  @spec noop(GenServer.server) :: {:ok} | error
  def noop(server) do
    execute(server, :NOOP, [])
  end

  @doc """
  Gets the pid of the `Memcache.Connection` process. Can be used to
  call functions in `Memcache.Connection`
  """
  @spec connection_pid(GenServer.server) :: pid
  def connection_pid(server) do
    connection(server)
  end

  ## Private
  defp get_option(server, option) do
    Agent.get(server, &(Map.get(&1, option)))
  end

  defp normalize_coder(spec) when is_tuple(spec), do: spec
  defp normalize_coder(module) when is_atom(module), do: {module, []}

  defp encode(server, value) do
    coder = get_option(server, :coder)
    apply(elem(coder, 0), :encode, [value, elem(coder, 1)])
  end

  defp decode(server, value) do
    coder = get_option(server, :coder)
    apply(elem(coder, 0), :decode, [value, elem(coder, 1)])
  end

  defp decode_response({:ok, value}, server) when is_binary(value) do
    {:ok, decode(server, value)}
  end
  defp decode_response({:ok, value, cas}, server) when is_binary(value) do
    {:ok, decode(server, value), cas}
  end
  defp decode_response(rest, _server), do: rest


  defp decode_multi_response({:ok, values}, server) when is_list(values) do
    {:ok, Enum.map(values, &(decode_response(&1, server)))}
  end
  defp decode_multi_response(rest, _server), do: rest


  defp connection(server) do
    get_option(server, :connection)
  end

  defp ttl_or_default(server, opts) do
    if Keyword.has_key?(opts, :ttl) do
      opts[:ttl]
    else
      get_option(server, :ttl)
    end
  end

  defp key_with_namespace(server, key) do
    namespace = get_option(server, :namespace)
    if namespace do
      "#{namespace}:#{key}"
    else
      key
    end
  end

  defp execute_k(server, command, [key | rest], opts \\ []) do
    execute(server, command, [key_with_namespace(server, key) | rest], opts)
    |> decode_response(server)
  end

  defp execute_kv(server, command, [key | [value | rest]], opts) do
    execute(server, command, [key_with_namespace(server, key) | [encode(server, value) | rest]], opts)
    |> decode_response(server)
  end

  defp execute(server, command, args, opts \\ []) do
    Connection.execute(connection(server), command, args, opts)
  end

  defp execute_quiet_k(server, commands) do
    commands = Enum.map(commands, fn ({command, [key | rest], opts}) ->
      {command, [key_with_namespace(server, key) | rest], opts}
    end)
    execute_quiet(server, commands)
    |> decode_multi_response(server)
  end

  defp execute_quiet_kv(server, commands) do
    commands = Enum.map(commands, fn ({command, [key | [value | rest]], opts}) ->
      {command, [key_with_namespace(server, key) | [encode(server, value) | rest]], opts}
    end)
    execute_quiet(server, commands)
    |> decode_multi_response(server)
  end

  defp execute_quiet(server, commands) do
    Connection.execute_quiet(connection(server), commands)
  end
end

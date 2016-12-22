defmodule Memcache.Api do
  @moduledoc """
  A behaviour module that provides a user friendly API to interact with the
  memcached server.

  ## Callbacks

  Most callbacks are implemented just using this module, but there
  are a few you must implement:

    `execute_k/4`
    `execute_kv/4`
    `execute/4`
    `connection_pid/1`
    `close/1`

  ## CAS

  CAS feature allows to atomically perform two commands on a key. Get
  the cas version number associated with a key during the first
  command and pass that value during the second command. The second
  command will fail if the value has changed by someone else in the
  mean time.

      {:ok, "hello", cas} = Memcache.Worker.get(pid, "key", cas: true)
      {:ok} = Memcache.Worker.set_cas(pid, "key", "world", cas)

  Memcache.Api module provides a *_cas variant for most of the
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

  @doc """
  Gets the value associated with the key. Returns `{:error, "Key not found"}`
  if the given key doesn't exist.

  Accepted option: `:cas`
  """
  @callback get(pid, key :: binary, Keyword.t) :: fetch_result

  @doc """
  Sets the key to value

  Accepted options: `:cas`, `:ttl`
  """
  @callback set(pid, key :: binary, value :: binary, Keyword.t) :: store_result

  @doc """
  Sets the key to value if the key exists and has CAS value equal to
  the provided value

  Accepted options: `:cas`, `:ttl`
  """
  @callback set_cas(pid, key :: binary, value :: binary, cas :: integer, Keyword.t) :: store_result

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
  @callback cas(pid, key :: binary, update :: fun, Keyword.t) :: result

  @doc """
  Sets the key to value if the key doesn't exist already. Returns
  `{:error, "Key exists"}` if the given key already exists.

  Accepted options: `:cas`, `:ttl`
  """
  @callback add(pid, key :: binary, value :: binary, Keyword.t) :: store_result

  @doc """
  Sets the key to value if the key already exists. Returns `{:error,
  "Key not found"}` if the given key doesn't exist.

  Accepted options: `:cas`, `:ttl`
  """
  @callback replace(pid, key :: binary, value :: binary, Keyword.t) :: store_result

  @doc """
  Sets the key to value if the key already exists and has CAS value
  equal to the provided value.

  Accepted options: `:cas`, `:ttl`
  """
  @callback replace_cas(pid, key :: binary, value :: binary, Keyword.t) :: store_result

  @doc """
  Removes the item with the given key value. Returns `{ :error, "Key
  not found" }` if the given key is not found
  """
  @callback delete(pid, key :: binary) :: store_result

  @doc """
  Removes the item with the given key value if the CAS value is equal
  to the provided value
  """
  @callback delete_cas(pid, key :: binary, cas :: integer) :: store_result

  @doc """
  Flush all the items in the server. `ttl` option will cause the flush
  to be delayed by the specified time.

  Accepted options: `:ttl`
  """
  @callback flush(pid, Keyword.t) :: store_result

  @doc """
  Appends the value to the end of the current value of the
  key. Returns `{:error, "Item not stored"}` if the item is not present
  in the server already

  Accepted options: `:cas`
  """
  @callback append(pid, key :: binary, value :: binary, Keyword.t) :: store_result

  @doc """
  Appends the value to the end of the current value of the
  key if the CAS value is equal to the provided value

  Accepted options: `:cas`
  """
  @callback append_cas(pid, key :: binary, value :: binary, cas :: integer, Keyword.t) :: store_result

  @doc """
  Prepends the value to the start of the current value of the
  key. Returns `{:error, "Item not stored"}` if the item is not present
  in the server already

  Accepted options: `:cas`
  """
  @callback prepend(pid, key :: binary, value :: binary, Keyword.t) :: store_result

  @doc """
  Prepends the value to the start of the current value of the
  key if the CAS value is equal to the provided value

  Accepted options: `:cas`
  """
  @callback prepend_cas(pid, key :: binary, value :: binary, Keyword.t) :: store_result

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
  @callback incr(pid, key :: binary, Keyword.t) :: fetch_integer_result

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
  @callback incr_cas(pid, key :: binary, cas :: integer, Keyword.t) :: fetch_integer_result

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
  @callback decr(pid, key :: binary, Keyword.t) :: fetch_integer_result

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
  @callback decr_cas(pid, key :: binary, cas :: integer, Keyword.t) :: fetch_integer_result

  @doc """
  Gets the specific set of server statistics
  """
  @callback stat(pid, String.t) :: HashDict.t | error

  @doc """
  Gets the version of the server
  """
  @callback version(pid) :: String.t | error

  @doc """
  Sends a noop command
  """
  @callback noop(pid) :: {:ok} | error

  @doc """
  Closes the connection to the memcached server.
  """
  @callback close(pid) :: {:ok}

  @doc """
  Gets the pid of the `Memcache.Connection` process. Can be used to
  call functions in `Memcache.Connection`
  """
  @callback connection_pid(pid) :: pid

  @callback execute_k(pid, command :: atom, args :: list, opts :: Keyword.t) :: any
  @callback execute_kv(pid, command :: atom, args :: list, opts :: Keyword.t) :: any
  @callback execute(pid, command :: atom, args :: list, opts :: Keyword.t) :: any


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


  defmacro __using__(_) do
    quote do
      @behaviour Memcache.Api

      def get(server \\ nil, key, opts \\ []) do
        execute_k(server, :GET, [key], opts)
      end

      def set(server \\ nil, key, value, opts \\ []) do
        set_cas(server, key, value, 0, opts)
      end

      def set_cas(server \\ nil, key, value, cas, opts \\ []) do
        execute_kv(server, :SET, [key, value, cas], opts)
      end

      @cas_error { :error, "Key exists" }

      def cas(server \\ nil, key, update, opts \\ []) do
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

      def add(server \\ nil, key, value, opts \\ []) do
        execute_kv(server, :ADD, [key, value], opts)
      end

      def replace(server \\ nil, key, value, opts \\ []) do
        replace_cas(server, key, value, 0, opts)
      end

      def replace_cas(server \\ nil, key, value, cas, opts \\ []) do
        execute_kv(server, :REPLACE, [key, value, cas], opts)
      end

      def delete(server \\ nil, key) do
        execute_k(server, :DELETE, [key])
      end

      def delete_cas(server \\ nil, key, cas) do
        execute_k(server, :DELETE, [key, cas])
      end

      def flush(server \\ nil, opts \\ []) do
        execute(server, :FLUSH, [Keyword.get(opts, :ttl, 0)])
      end

      def append(server \\ nil, key, value, opts \\ []) do
        execute_kv(server, :APPEND, [key, value], opts)
      end

      def append_cas(server \\ nil, key, value, cas, opts \\ []) do
        execute_kv(server, :APPEND, [key, value, cas], opts)
      end

      def prepend(server \\ nil, key, value, opts \\ []) do
        execute_kv(server, :PREPEND, [key, value], opts)
      end

      def prepend_cas(server \\ nil, key, value, cas, opts \\ []) do
        execute_kv(server, :PREPEND, [key, value, cas], opts)
      end

      def incr(server \\ nil, key, opts \\ []) do
        incr_cas(server, key, 0, opts)
      end

      def incr_cas(server \\ nil, key, cas, opts \\ []) do
        defaults = [by: 1, default: 0]
        opts = Keyword.merge(defaults, opts)
        execute_k(server, :INCREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas], opts)
      end

      def decr(server \\ nil, key, opts \\ []) do
        decr_cas(server, key, 0, opts)
      end

      def decr_cas(server \\ nil, key, cas, opts \\ []) do
        defaults = [by: 1, default: 0]
        opts = Keyword.merge(defaults, opts)
        execute_k(server, :DECREMENT, [key, Keyword.get(opts, :by), Keyword.get(opts, :default), cas], opts)
      end

      def stat(server \\ nil, key \\ []) do
        execute(server, :STAT, key)
      end

      def version(server \\ nil) do
        execute(server, :VERSION, [])
      end

      def noop(server \\ nil) do
        execute(server, :NOOP, [])
      end

    end
  end
end

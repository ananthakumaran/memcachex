defmodule Memcache.Worker do
  @moduledoc """
  """

  use Memcache.Api

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
  """
  @spec start_link(Keyword.t) :: GenServer.on_start
  def start_link(connection_options \\ []) do
    connection_options = Keyword.merge(@default_opts, connection_options)
      |> Keyword.update!(:coder, &normalize_coder/1)
    extra_opts = [:ttl, :namespace, :coder]
    state = connection_options
      |> Keyword.take(extra_opts)
      |> Enum.into(%{})

    Agent.start_link(fn ->
      {:ok, pid} = Connection.start_link(Keyword.drop(connection_options, extra_opts))
      Map.put(state, :connection, pid)
    end)
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
  Gets the pid of the `Memcache.Connection` process. Can be used to
  call functions in `Memcache.Connection`
  """
  @spec connection_pid(GenServer.server) :: pid
  def connection_pid(server) do
    connection(server)
  end

  def execute_k(server, command, [key | rest], opts \\ []) do
    execute(server, command, [key_with_namespace(server, key) | rest], opts)
    |> decode_response(server)
  end

  def execute_kv(server, command, [key | [value | rest]], opts) do
    execute(server, command, [key_with_namespace(server, key) | [encode(server, value) | rest]], opts)
    |> decode_response(server)
  end

  def execute(server, command, args, opts \\ []) do
    args = if command in [:SET, :REPLACE, :ADD, :INCREMENT, :DECREMENT] do
      args ++ [ttl_or_default(server, opts)]
    else
      args
    end
    Connection.execute(connection(server), command, args, opts)
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

  defp connection(server) do
    get_option(server, :connection)
  end

  defp ttl_or_default(server, opts) do
    Keyword.get(opts, :ttl, get_option(server, :ttl))
  end

  defp key_with_namespace(server, key) do
    namespace = get_option(server, :namespace)
    if namespace do
      "#{namespace}:#{key}"
    else
      key
    end
  end

end

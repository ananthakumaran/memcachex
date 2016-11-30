defmodule Memcache.Worker do

  use GenServer
  use Memcache.Api

  alias Memcache.Connection

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
  @spec start_link({Keyword.t, Keyword.t}) :: GenServer.on_start
  def start_link({connection_options, options} \\ {[], []}) do
    GenServer.start_link(__MODULE__, connection_options, options)
  end

  ## Server Callbacks

  def init(connection_options) do
    extra_opts = [:ttl, :namespace, :coder]
    connection_options = Keyword.merge(@default_opts, connection_options)
    |> Keyword.update!(:coder, &normalize_coder/1)
    state = connection_options |> Keyword.take(extra_opts) |> Enum.into(%{})
    {:ok, pid} = Connection.start_link(Keyword.drop(connection_options, extra_opts))
    state = Map.put(state, :connection, pid)

    {:ok, state}
  end

  def handle_call(:close, _from, state) do
    connection = Map.get(state, :connection)
    result = Connection.close(connection)
    {:reply, result, state}
  end

  def handle_call({:execute, command, args, opts}, _from, state) do
    connection = Map.get(state, :connection)
    result = Connection.execute(connection, command, args, opts)
    {:reply, result, state}
  end

end

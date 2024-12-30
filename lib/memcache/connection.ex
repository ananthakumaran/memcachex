defmodule Memcache.Connection do
  @moduledoc """
  This module provides low level API to connect and execute commands
  on a memcached server.
  """
  require Logger
  use Connection
  alias Memcache.Protocol
  alias Memcache.Receiver
  alias Memcache.Utils
  alias Memcache.Transport

  defmodule State do
    @moduledoc false

    defstruct opts: nil,
              sock: nil,
              backoff_current: nil,
              receiver: nil,
              receiver_queue: nil,
              server: nil,
              transport: nil
  end

  @doc """
  Starts a connection to memcached server.

  The actual TCP connection to the memcached server is established
  asynchronously after the `start_link/2` returns.

  This function accepts two option lists. The first one specifies the
  options to connect to the memcached server. The second option is
  passed directly to the underlying `GenServer.start_link/3`, so it
  can be used to create named process.

  Memcachex automatically tries to reconnect in case of tcp connection
  failures. It starts with a `:backoff_initial` wait time and
  increases the wait time exponentially on each successive failures
  until it reaches the `:backoff_max`. After that, it waits for
  `:backoff_max` after each failure.

  ## Connection Options

  * `:hostname` - (string) hostname of the memcached server. Defaults
    to `"localhost"`
  * `:port` - (integer) port on which the memcached server is
    listening. Defaults to `11211`
  * `:backoff_initial` - (integer) initial backoff (in milliseconds)
    to be used in case of connection failure. Defaults to `500`
  * `:backoff_max` - (integer) maximum allowed interval between two
    connection attempt. Defaults to `30_000`
  * `:connect_timeout` - (integer) connection timeout (in milliseconds) at
    which to terminate the connection attempt in case of an
    unresponsive host. Defaults to :infinity

  * `:auth` - (tuple) only plain authentication method is
    supported. It is specified using the following format `{:plain,
    "username", "password"}`. Defaults to `nil`.

  * `:ssl_options` - (keyword) SSL options, see `https://www.erlang.org/doc/man/ssl#type-tls_client_option`.

  ## Examples

      {:ok, pid} = Memcache.Connection.start_link()

  """
  @spec start_link(Keyword.t(), Keyword.t()) :: GenServer.on_start()
  def start_link(connection_options \\ [], options \\ []) do
    connection_options = with_defaults(connection_options)
    Connection.start_link(__MODULE__, connection_options, options)
  end

  @default_opts [
    backoff_initial: 500,
    backoff_max: 30_000,
    connect_timeout: :infinity,
    hostname: ~c"localhost",
    port: 11_211,
    transport: :gen_tcp
  ]

  defp with_defaults(opts) do
    @default_opts
    |> Keyword.merge(opts)
    |> Keyword.update!(:hostname, &to_charlist/1)
  end

  @doc """
  Executes the command with the given args

  ## options

  * `:cas` - (boolean) returns the CAS value associated with the
    data. This value will be either in second or third position
    of the returned tuple depending on the command. Defaults to `false`

  ## Examples

      iex> {:ok, pid} = Memcache.Connection.start_link()
      iex> {:ok} = Memcache.Connection.execute(pid, :SET, ["hello", "world"])
      iex> {:ok, "world"} = Memcache.Connection.execute(pid, :GET, ["hello"])
      {:ok, "world"}

  """
  @spec execute(GenServer.server(), atom, [binary], Keyword.t()) :: Memcache.result()
  def execute(pid, command, args, options \\ []) do
    with_telemetry([{command, args, options}], fn ->
      Connection.call(pid, {:execute, command, args, %{cas: Keyword.get(options, :cas, false)}})
    end)
  end

  @doc """
  Executes the list of quiet commands

  ## Examples

      iex> {:ok, pid} = Memcache.Connection.start_link()
      iex> {:ok, [{:ok}, {:ok}]} = Memcache.Connection.execute_quiet(pid, [{:SETQ, ["1", "one"]}, {:SETQ, ["2", "two"]}])
      iex> Memcache.Connection.execute_quiet(pid, [{:GETQ, ["1"]}, {:GETQ, ["2"]}])
      {:ok, [{:ok, "one"}, {:ok, "two"}]}

  """
  @spec execute_quiet(GenServer.server(), [{atom, [binary]} | {atom, [binary], Keyword.t()}]) ::
          {:ok, [Memcache.result()]} | {:error, atom}
  def execute_quiet(pid, commands) do
    with_telemetry(commands, fn ->
      Connection.call(pid, {:execute_quiet, commands})
    end)
  end

  defp with_telemetry(commands, callback) do
    telemetry_metadata = %{
      commands: commands,
      start_time: System.system_time()
    }

    start_time = System.monotonic_time()
    {result, %{server: server}} = callback.()
    end_time = System.monotonic_time()
    telemetry_metadata = Map.put(telemetry_metadata, :server, server)
    measurements = %{elapsed_time: end_time - start_time}

    case normalize_result(result) do
      {:error, reason} ->
        telemetry_metadata = Map.put(telemetry_metadata, :reason, reason)
        :ok = :telemetry.execute([:memcachex, :commands_error], measurements, telemetry_metadata)

      {:ok, results} ->
        telemetry_metadata = Map.put(telemetry_metadata, :results, results)
        :ok = :telemetry.execute([:memcachex, :commands], measurements, telemetry_metadata)
    end

    result
  end

  defp normalize_result(result) do
    case result do
      {:error, reason} when is_atom(reason) -> {:error, reason}
      {:ok, results} when is_list(results) -> {:ok, results}
      _ -> {:ok, [result]}
    end
  end

  @doc """
  Closes the connection to the memcached server.

  ## Examples

      iex> {:ok, pid} = Memcache.Connection.start_link()
      iex> Memcache.Connection.close(pid)
      {:ok}

  """
  @spec close(GenServer.server()) :: {:ok}
  def close(pid) do
    :ok = GenServer.stop(pid)
    {:ok}
  end

  def init(opts) do
    transport = if Keyword.get(opts, :ssl, false), do: :ssl, else: :gen_tcp
    {:connect, :init, %State{opts: opts, server: Utils.format_host(opts), transport: transport}}
  end

  def connect(info, %State{opts: opts, server: server} = s) do
    sock_opts = [:binary, active: false, packet: :raw]

    case connect_and_authenticate(
           opts[:hostname],
           opts[:port],
           sock_opts,
           opts[:connect_timeout],
           s
         ) do
      {:ok, sock} ->
        reconnected = info == :backoff || info == :reconnect

        _ =
          if reconnected do
            Logger.info(["Reconnected to Memcache (", server, ")"])
          end

        :ok =
          :telemetry.execute([:memcachex, :connection], %{}, %{
            server: server,
            reconnected: reconnected
          })

        {:ok, receiver} = Receiver.start_link([sock, self(), server])
        receiver_queue = MapSet.new()

        state = %{
          s
          | sock: sock,
            backoff_current: nil,
            receiver: receiver,
            receiver_queue: receiver_queue
        }

        {:ok, state}

      {:error, reason} ->
        backoff = get_backoff(s)

        _ =
          Logger.error([
            "Failed to connect to Memcache (",
            server,
            "): ",
            Utils.format_error(reason),
            ". Sleeping for ",
            to_string(backoff),
            "ms."
          ])

        :ok =
          :telemetry.execute([:memcachex, :connection_error], %{}, %{
            server: server,
            reason: reason
          })

        {:backoff, backoff, %{s | backoff_current: backoff}}

      {:stop, reason} ->
        {:stop, reason, s}
    end
  end

  def disconnect({:error, reason}, %State{server: server} = s) do
    _ =
      Logger.error([
        "Disconnected from Memcache (",
        server,
        "): ",
        Utils.format_error(reason)
      ])

    :ok =
      :telemetry.execute([:memcachex, :connection_error], %{}, %{
        server: server,
        reason: reason
      })

    cleanup(s)

    {:connect, :reconnect,
     %{s | sock: nil, backoff_current: nil, receiver: nil, receiver_queue: nil}}
  end

  def handle_call({:execute, _command, _args, _opts}, _from, %State{sock: nil} = s) do
    {:reply, error_response(s), s}
  end

  def handle_call({:execute, command, args, opts}, from, s) do
    with :ok <- maybe_deactivate_sock(s) do
      send_and_receive(s, from, command, args, opts)
    end
  end

  def handle_call({:execute_quiet, _commands}, _from, %State{sock: nil} = s) do
    {:reply, error_response(s), s}
  end

  def handle_call({:execute_quiet, commands}, from, s) do
    with :ok <- maybe_deactivate_sock(s) do
      send_and_receive_quiet(s, from, commands)
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    error = {:error, :closed}
    {:disconnect, error, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    error = {:error, reason}
    {:disconnect, error, state}
  end

  def handle_info({:receiver, :disconnect, error, receiver}, %State{receiver: receiver} = state) do
    {:disconnect, error, state}
  end

  def handle_info({:receiver, :done, client, receiver}, %State{receiver: receiver} = state) do
    receiver_queue = MapSet.delete(state.receiver_queue, client)
    state = %{state | receiver_queue: receiver_queue}
    maybe_activate_sock(state)
  end

  def handle_info(msg, state) do
    _ = Logger.warning(["Unknown message: ", inspect(msg)])
    {:noreply, state}
  end

  def terminate(_reason, state) do
    cleanup(state)
  end

  ## Private ##

  def cleanup(%State{sock: sock, receiver: receiver, receiver_queue: receiver_queue} = s) do
    if sock do
      :ok = Transport.close(sock)
    end

    if receiver do
      try do
        Receiver.stop(receiver)
      catch
        :exit, _ -> :ok
      end
    end

    if receiver_queue do
      Enum.each(receiver_queue, fn from ->
        Connection.reply(from, error_response(s))
      end)
    end

    :ok
  end

  defp error_response(%State{server: server}, reason \\ :closed) do
    {{:error, reason}, %{server: server}}
  end

  defp maybe_activate_sock(state) do
    if Enum.empty?(state.receiver_queue) do
      case Transport.setopts(state.sock, active: :once) do
        :ok -> {:noreply, state}
        error -> {:disconnect, error, state}
      end
    else
      {:noreply, state}
    end
  end

  defp maybe_deactivate_sock(state) do
    if Enum.empty?(state.receiver_queue) do
      case Transport.setopts(state.sock, active: false) do
        :ok -> :ok
        error -> {:disconnect, error, error_response(state), state}
      end
    else
      :ok
    end
  end

  defp send_and_receive(%State{sock: sock} = s, from, command, args, opts) do
    packet = serialize(command, args)

    case Transport.send(sock, packet) do
      :ok ->
        s = enqueue_receiver(s, from)
        :ok = Receiver.read(s.receiver, from, command, opts)
        {:noreply, s}

      {:error, reason} = error ->
        {:disconnect, error, error_response(s, reason), s}
    end
  end

  defp send_and_receive_quiet(%State{sock: sock} = s, from, commands) do
    {packet, commands, i} = Enum.reduce(commands, {[], [], 1}, &accumulate_commands/2)
    packet = [packet | serialize(:NOOP, [], i)]

    case Transport.send(sock, packet) do
      :ok ->
        s = enqueue_receiver(s, from)
        :ok = Receiver.read_quiet(s.receiver, from, Enum.reverse([{i, :NOOP, [], []} | commands]))
        {:noreply, s}

      {:error, reason} = error ->
        {:disconnect, error, error_response(s, reason), s}
    end
  end

  defp enqueue_receiver(state, from) do
    receiver_queue = MapSet.put(state.receiver_queue, from)
    %{state | receiver_queue: receiver_queue}
  end

  defp accumulate_commands({command, args}, {packet, commands, i}) do
    {[packet | serialize(command, args, i)], [{i, command, args, %{cas: false}} | commands],
     i + 1}
  end

  defp accumulate_commands({command, args, options}, {packet, commands, i}) do
    {[packet | serialize(command, args, i)],
     [{i, command, args, %{cas: Keyword.get(options, :cas, false)}} | commands], i + 1}
  end

  defp get_backoff(s) do
    if s.backoff_current do
      Utils.next_backoff(s.backoff_current, s.opts[:backoff_max])
    else
      s.opts[:backoff_initial]
    end
  end

  defp connect_and_authenticate(host, port, sock_opts, timeout, state) do
    case Transport.connect(state.transport, host, port, sock_opts, timeout, state.opts) do
      {:ok, sock} ->
        with {:ok} <- authenticate(sock, state.opts),
             # Make sure the socket is usable
             {:ok, _} <- execute_command(sock, :NOOP, []),
             :ok <- Transport.setopts(sock, active: :once) do
          {:ok, sock}
        else
          error ->
            Transport.close(sock)
            error
        end

      error ->
        error
    end
  end

  defp authenticate(sock, opts) do
    case opts[:auth] do
      nil -> {:ok}
      {:plain, username, password} -> auth_plain(sock, username, password)
      _ -> {:stop, "Memcachex client only supports :plain authentication type"}
    end
  end

  defp execute_command(sock, command, args) do
    packet = serialize(command, args)

    case Transport.send(sock, packet) do
      :ok -> recv_response(sock, command)
      error -> error
    end
  end

  defp auth_plain(sock, username, password) do
    case execute_command(sock, :AUTH_LIST, []) do
      {:ok, {:ok, list}} ->
        supported = String.split(list, " ")

        if Enum.member?(supported, "PLAIN") do
          auth_plain_continue(sock, username, password)
        else
          {:stop, "Server doesn't support PLAIN authentication"}
        end

      {:ok, {:error, "Unknown command"}} ->
        _ = Logger.warning("Authentication not required/supported by server")
        {:ok}

      {:ok, {:error, reason}} ->
        {:stop, reason}

      error ->
        error
    end
  end

  defp auth_plain_continue(sock, username, password) do
    case execute_command(sock, :AUTH_START, ["PLAIN", "\0#{username}\0#{password}"]) do
      {:ok, {:ok}} ->
        {:ok}

      {:ok, {:error, reason}} ->
        {:stop, reason}

      error ->
        error
    end
  end

  defp recv_response(sock, command) do
    case Receiver.recv_response(command, sock, <<>>, %{cas: false}) do
      {:ok, response, <<>>} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp serialize(command, args, opaque \\ 0) do
    apply(Protocol, :to_binary, [command | [opaque | args]])
  end
end

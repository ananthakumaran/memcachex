defmodule Memcache.Connection do
  @moduledoc """
  This module provides low level API to connect and execute commands
  on a memcached server.
  """
  require Logger
  use Connection
  alias Memcache.Protocol
  alias Memcache.Utils

  defmodule State do
    @moduledoc false

    defstruct opts: nil, sock: nil, backoff_current: nil
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

  ## Example

      {:ok, pid} = Memcache.Connection.start_link()

  """
  @spec start_link(Keyword.t, Keyword.t) :: GenServer.on_start
  def start_link(connection_options \\ [], options \\ []) do
    connection_options = with_defaults(connection_options)
    Connection.start_link(__MODULE__, connection_options, options)
  end

  @default_opts [
    backoff_initial: 500,
    backoff_max: 30_000,
    hostname: 'localhost',
    port: 11211
  ]

  defp with_defaults(opts) do
    Keyword.merge(@default_opts, opts)
    |> Keyword.update!(:hostname, (&if is_binary(&1), do: String.to_char_list(&1), else: &1))
  end

  @doc """
  Executes the command with the given args

  ## options

  * `:cas` - (boolean) returns the CAS value associated with the
    data. This value will be either in second or third position
    of the returned tuple depending on the command. Defaults to `false`

  ## Example

      iex> {:ok, pid} = Memcache.Connection.start_link()
      iex> {:ok} = Memcache.Connection.execute(pid, :SET, ["hello", "world"])
      iex> {:ok, "world"} = Memcache.Connection.execute(pid, :GET, ["hello"])
      {:ok, "world"}

  """
  @spec execute(GenServer.server, atom, [binary], Keyword.t) :: Memcache.result
  def execute(pid, command, args, options \\ []) do
    Connection.call(pid, { :execute, command, args, %{cas: Keyword.get(options, :cas, false)} })
  end

  @doc """
  Executes the list of quiet commands

  ## Example

      iex> {:ok, pid} = Memcache.Connection.start_link()
      iex> {:ok, [{:ok}, {:ok}]} = Memcache.Connection.execute_quiet(pid, [{:SETQ, ["1", "one"]}, {:SETQ, ["2", "two"]}])
      iex> Memcache.Connection.execute_quiet(pid, [{:GETQ, ["1"]}, {:GETQ, ["2"]}])
      {:ok, [{:ok, "one"}, {:ok, "two"}]}

  """
  @spec execute_quiet(GenServer.server, [{atom, [binary]}]) :: {:ok, [Memcache.result]} | {:error, atom}
  def execute_quiet(pid, commands) do
    Connection.call(pid, { :execute_quiet, commands })
  end

  @doc """
  Closes the connection to the memcached server.

  ## Example
      iex> {:ok, pid} = Memcache.Connection.start_link()
      iex> Memcache.Connection.close(pid)
      {:ok}
  """
  @spec close(GenServer.server) :: {:ok}
  def close(pid) do
    Connection.call(pid, { :close })
  end

  def init(opts) do
    { :connect, :init, %State{opts: opts} }
  end

  def connect(info, %State{opts: opts} = s) do
    sock_opts = [:binary, active: false, packet: :raw]
    case :gen_tcp.connect(opts[:hostname], opts[:port], sock_opts) do
      { :ok, sock } ->
        if info == :backoff || info == :reconnect do
          Logger.info(["Reconnected to Memcache (", Utils.format_host(opts), ")"])
        end
        :inet.setopts(sock, [active: :once])
        { :ok, %{s | sock: sock, backoff_current: nil } }
      { :error, reason } ->
        Logger.error(["Failed to connect to Memcache (", Utils.format_host(opts), "): ", Utils.format_error(reason)])
        backoff = if !s.backoff_current do
          s.opts[:backoff_initial]
        else
          Utils.next_backoff(s.backoff_current, s.opts[:backoff_max])
        end
        { :backoff, backoff, %{s | backoff_current: backoff} }
    end
  end

  def disconnect({ :close, from }, %State{ sock: sock } = state) do
    :ok = :gen_tcp.close(sock)
    Connection.reply(from, { :ok })
    {:stop, :normal, %{ state | sock: nil }}
  end

  def disconnect({:error, reason}, %State{ sock: sock, opts: opts } = s) do
    Logger.error(["Disconnected from Memcache (", Utils.format_host(opts), "): ", Utils.format_error(reason)])
    :ok = :gen_tcp.close(sock)
    {:connect, :reconnect, %{s | sock: nil, backoff_current: nil}}
  end

  def handle_call({ :execute, _command, _args, _opts }, _from, %State{ sock: nil } = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({ :execute, command, args, opts }, _from, %State{ sock: sock } = s) do
    :inet.setopts(sock, [active: false])
    packet = apply(Protocol, :to_binary, [command | args])
    result = case :gen_tcp.send(sock, packet) do
               :ok -> recv_response(command, s, opts)
               { :error, _reason } = error -> { :disconnect, error, error, s }
             end
    :inet.setopts(sock, [active: :once])
    result
  end

  def handle_call({ :execute_quiet, _commands }, _from, %State{ sock: nil } = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({ :execute_quiet, commands }, _from, %State{ sock: sock } = s) do
    :inet.setopts(sock, [active: false])
    { packet, commands, i } = Enum.reduce(commands, { <<>>, [], 1 }, fn ({ command, args }, { packet, commands, i }) ->
      { packet <> apply(Protocol, :to_binary, [command | [i | args]]), [{ i, command, args } | commands], i + 1 }
    end)
    packet = packet <> Protocol.to_binary(:NOOP, i)
    result = case :gen_tcp.send(sock, packet) do
               :ok -> recv_response_quiet(Enum.reverse([ { i, :NOOP, [] } | commands]), s, [], <<>>)
               { :error, _reason } = error -> { :disconnect, error, error, s }
             end
    :inet.setopts(sock, [active: :once])
    result
  end

  def handle_call({ :close }, from, state) do
    { :disconnect, { :close, from }, state }
  end

  def handle_info({:tcp_closed, _socket}, state) do
    error = {:error, :tcp_closed}
    { :disconnect, error, state }
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    error = {:error, reason}
    { :disconnect, error, state }
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_reason, %State{ sock: sock }) do
    if sock do
      :gen_tcp.close(sock)
    end
  end

  ## Private ##

  defp recv_response(:STAT, s, _opts) do
    recv_stat(s, HashDict.new)
  end

  defp recv_response(_command, s, %{cas: cas}) do
    header = recv_header(s)
    response = recv_body(header, s)
    if cas do
      case response do
        { :reply, result, state } ->
          result = case result do
                     { :ok } -> { :ok, header.cas }
                     { :ok, value } -> { :ok, value, header.cas }
                     err -> err
                   end
          { :reply, result, state }
          err -> err
      end
    else
      response
    end
  end

  defp recv_header(%State{ sock: sock } = s) do
    case :gen_tcp.recv(sock, 24) do
      { :ok, raw_header } ->
        Protocol.parse_header(raw_header)
      { :error, _reason } = error -> { :disconnect, error, error, s }
    end
  end

  defp recv_body(header, %State{ sock: sock } = s) do
    body_size = Protocol.total_body_size(header)
    if body_size > 0 do
      case :gen_tcp.recv(sock, body_size) do
        { :ok, body } ->
          response = Protocol.parse_body(header, body)
          { :reply, response, s }
        { :error, _reason } = error -> { :disconnect, error, error, s }
      end
    else
      response = Protocol.parse_body(header, :empty)
      { :reply, response, s }
    end
  end

  defp recv_stat(s, results) do
    case recv_header(s) |> recv_body(s) do
      { :reply, { :ok, :done }, _ } -> { :reply, { :ok, results }, s }
      { :reply, { :ok, key, val }, _ } -> recv_stat(s, HashDict.put(results, key, val))
      err -> err
    end
  end

  defp recv_response_quiet([], s, results, _buffer) do
    { :reply, { :ok, Enum.reverse(tl(results)) }, s }
  end

  defp recv_response_quiet(commands, s, results, buffer) when byte_size(buffer) >= 24 do
    { header_raw, rest } = cut(buffer, 24)
    header = Protocol.parse_header(header_raw)
    body_size = Protocol.total_body_size(header)
    if body_size > 0 do
      case read_more_if_needed(s, rest, body_size) do
        { :ok, buffer } ->
          { body, rest } = cut(buffer, body_size)
          { rest_commands, results } = match_response(commands, results, Protocol.parse_body(header, body))
          recv_response_quiet(rest_commands, s, results, rest)
        err -> err
      end
    else
      { rest_commands, results } = match_response(commands, results, Protocol.parse_body(header, :empty))
      recv_response_quiet(rest_commands, s, results, rest)
    end
  end

  defp recv_response_quiet(commands, s, results, buffer) do
    case read_more_if_needed(s, buffer, 24) do
      { :ok, buffer } -> recv_response_quiet(commands, s, results, buffer)
      err -> err
    end
  end

  defp match_response([ { i, _command, _args } | rest ], results, { i, response }) do
    { rest, [response | results] }
  end

  defp match_response([ { _i , command, _args } | rest ], results, response_with_index) do
    match_response(rest, [Protocol.quiet_response(command) | results], response_with_index)
  end

  defp read_more_if_needed(_sock, buffer, min_required) when byte_size(buffer) >= min_required do
    { :ok, buffer }
  end

  defp read_more_if_needed(%State{ sock: sock } = s, buffer, min_required) do
    case :gen_tcp.recv(sock, 0) do
      { :ok, data } -> read_more_if_needed(s, buffer <> data, min_required)
      { :error, _reason } = error -> { :disconnect, error, error, s }
    end
  end

  defp cut(bin, at) do
    first = binary_part(bin, 0, at)
    rest = binary_part(bin, at, byte_size(bin) - at)
    { first, rest }
  end
end

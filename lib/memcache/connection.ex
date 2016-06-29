defmodule Memcache.Connection do
  require Logger
  use Connection
  alias Memcache.Protocol
  alias Memcache.Utils

  defmodule State do
    defstruct opts: nil, sock: nil
  end

  @spec start_link(Keyword.t) :: { :ok, pid } | { :error, term }
  def start_link(opts) do
    opts = with_defaults(opts)
    Connection.start_link(__MODULE__, opts, [])
  end

  def execute(pid, command, args) do
    Connection.call(pid, { :execute, command, args })
  end

  def execute_quiet(pid, commands) do
    Connection.call(pid, { :execute_quiet, commands })
  end

  def close(pid) do
    Connection.call(pid, { :close })
  end

  def init(opts) do
    { :connect, :init, %State{opts: opts} }
  end

  def connect(info, %State{opts: opts} = s) do
    sock_opts = [ { :active, false }, { :packet, :raw }, :binary ]
    case :gen_tcp.connect(opts[:hostname], opts[:port], sock_opts) do
      { :ok, sock } ->
        if info == :backoff do
          Logger.info(["Reconnected to Memcache"])
        end
        { :ok, %State{ sock: sock, opts: opts } }
      { :error, reason } ->
        Logger.error(["Failed to connect to Memcache: ", Utils.format_error(reason)])
        { :backoff, 1000, s }
    end
  end

  def disconnect(:close, state) do
    {:stop, :normal, state}
  end

  def disconnect({:error, reason}, %State{ sock: sock } = s) do
    Logger.error(["Disconnected from Memcache: ", Utils.format_error(reason)])
    :ok = :gen_tcp.close(sock)
    {:connect, :reconnect, %{s | sock: nil}}
  end

  def handle_call({ :execute, _command, _args }, _from, %State{ sock: nil } = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({ :execute, command, args }, _from, %State{ sock: sock } = s) do
    packet = apply(Protocol, :to_binary, [command | args])
    case :gen_tcp.send(sock, packet) do
      :ok -> recv_response(command, s)
      { :error, _reason } = error -> { :disconnect, error, error, s }
    end
  end

  def handle_call({ :execute_quiet, _commands }, _from, %State{ sock: nil } = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({ :execute_quiet, commands }, _from, %State{ sock: sock } = s) do
    { packet, commands, i } = Enum.reduce(commands, { <<>>, [], 1 }, fn ({ command, args }, { packet, commands, i }) ->
      { packet <> apply(Protocol, :to_binary, [command | [i | args]]), [{ i, command, args } | commands], i + 1 }
    end)
    packet = packet <> Protocol.to_binary(:NOOP, i)
    case :gen_tcp.send(sock, packet) do
      :ok -> recv_response_quiet(Enum.reverse([ { i, :NOOP, [] } | commands]), s, [], <<>>)
      { :error, _reason } = error -> { :disconnect, error, error, s }
    end
  end

  def terminate(_reason, %State{ sock: sock }) do
    if sock do
      :gen_tcp.close(sock)
    end
  end

  ## Private ##

  defp recv_response(:STAT, s) do
    recv_stat(s, HashDict.new)
  end

  defp recv_response(_command, s) do
    recv_header(s)
  end

  defp recv_header(%State{ sock: sock } = s) do
    case :gen_tcp.recv(sock, 24) do
      { :ok, raw_header } ->
        header = Protocol.parse_header(raw_header)
        recv_body(header, s)
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
    case recv_header(s) do
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

  defp with_defaults(opts) do
    opts
    |> Keyword.put_new(:port, 11211)
    |> Keyword.update!(:hostname, (&if is_binary(&1), do: String.to_char_list(&1), else: &1))
  end

  defp cut(bin, at) do
    first = binary_part(bin, 0, at)
    rest = binary_part(bin, at, byte_size(bin) - at)
    { first, rest }
  end
end

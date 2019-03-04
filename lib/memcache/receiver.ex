defmodule Memcache.Receiver do
  @moduledoc false
  use GenServer
  alias Memcache.Protocol

  defmodule State do
    @moduledoc false

    defstruct sock: nil, parent: nil, buffer: <<>>
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def stop(receiver) do
    GenServer.stop(receiver)
  end

  def read(receiver, client, command, opts) do
    GenServer.cast(receiver, {:read, client, command, opts})
  end

  def read_quiet(receiver, client, commands) do
    GenServer.cast(receiver, {:read_quiet, client, commands})
  end

  def init([sock, parent]) do
    {:ok, %State{sock: sock, parent: parent}}
  end

  def handle_cast({:read, client, command, opts}, %State{sock: sock, buffer: buffer} = s) do
    reply_or_disconnect(recv_response(command, sock, buffer, opts), client, s)
  end

  def handle_cast({:read_quiet, client, commands}, %State{sock: sock, buffer: buffer} = s) do
    reply_or_disconnect(recv_response_quiet(commands, sock, [], buffer), client, s)
  end

  defp reply_or_disconnect({:ok, response, buffer}, client, s) do
    Connection.reply(client, response)
    send(s.parent, {:receiver, :done, client, self()})
    {:noreply, %{s | buffer: buffer}}
  end

  defp reply_or_disconnect(error, _client, s) do
    send(s.parent, {:receiver, :disconnect, error, self()})
    {:stop, :normal, s}
  end

  def recv_response(:STAT, sock, buffer, _opts) do
    recv_stat(sock, buffer, Map.new())
  end

  def recv_response(_command, sock, buffer, %{cas: cas}) do
    with {:ok, header, buffer} <- recv_header(sock, buffer),
         {:ok, response, buffer} <- recv_body(header, sock, buffer) do
      if cas do
        {:ok, append_cas_version(response, header), buffer}
      else
        {:ok, response, buffer}
      end
    end
  end

  defp recv_header_and_body(sock, buffer) do
    with {:ok, header, buffer} <- recv_header(sock, buffer) do
      recv_body(header, sock, buffer)
    end
  end

  defp recv_header(sock, buffer) do
    with {:ok, raw_header, buffer} <- read(sock, buffer, 24) do
      {:ok, Protocol.parse_header(raw_header), buffer}
    end
  end

  defp recv_body(header, sock, buffer) do
    body_size = Protocol.total_body_size(header)

    if body_size > 0 do
      with {:ok, body, buffer} <- read(sock, buffer, body_size) do
        response =
          header
          |> Protocol.parse_body(body)
          |> elem(1)

        {:ok, response, buffer}
      end
    else
      response =
        header
        |> Protocol.parse_body(:empty)
        |> elem(1)

      {:ok, response, buffer}
    end
  end

  defp recv_stat(sock, buffer, results) do
    case recv_header_and_body(sock, buffer) do
      {:ok, {:ok, :done}, buffer} -> {:ok, {:ok, results}, buffer}
      {:ok, {:ok, key, val}, buffer} -> recv_stat(sock, buffer, Map.put(results, key, val))
      err -> err
    end
  end

  defp append_cas_version({:ok}, %{cas: cas_version}), do: {:ok, cas_version}
  defp append_cas_version({:ok, value}, %{cas: cas_version}), do: {:ok, value, cas_version}
  defp append_cas_version({:ok, value, flags}, %{cas: cas_version}), do: {:ok, value, cas_version, flags}
  defp append_cas_version(error, %{cas: _cas_version}), do: error

  defp recv_response_quiet([], _sock, results, buffer) do
    {:ok, {:ok, Enum.reverse(tl(results))}, buffer}
  end

  defp recv_response_quiet(commands, sock, results, buffer) do
    with {:ok, header_raw, rest} <- read(sock, buffer, 24) do
      header = Protocol.parse_header(header_raw)
      body_size = Protocol.total_body_size(header)

      if body_size > 0 do
        case read(sock, rest, body_size) do
          {:ok, body, rest} ->
            {rest_commands, results} =
              match_response(commands, results, header, Protocol.parse_body(header, body))

            recv_response_quiet(rest_commands, sock, results, rest)

          err ->
            err
        end
      else
        {rest_commands, results} =
          match_response(commands, results, header, Protocol.parse_body(header, :empty))

        recv_response_quiet(rest_commands, sock, results, rest)
      end
    end
  end

  defp match_response([{i, _command, _args, %{cas: true}} | rest], results, header, {i, response}) do
    {rest, [append_cas_version(response, header) | results]}
  end

  defp match_response([{i, _command, _args, _opts} | rest], results, _header, {i, response}) do
    {rest, [response | results]}
  end

  defp match_response([{_i, command, _args, _opts} | rest], results, header, response_with_index) do
    match_response(
      rest,
      [Protocol.quiet_response(command) | results],
      header,
      response_with_index
    )
  end

  defp read(_sock, buffer, min_required) when byte_size(buffer) >= min_required do
    {requested, rest} = cut(buffer, min_required)
    {:ok, requested, rest}
  end

  defp read(sock, buffer, min_required) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} -> read(sock, buffer <> data, min_required)
      {:error, reason} -> {:error, reason}
    end
  end

  defp cut(bin, at) do
    first = binary_part(bin, 0, at)
    rest = binary_part(bin, at, byte_size(bin) - at)
    {first, rest}
  end
end

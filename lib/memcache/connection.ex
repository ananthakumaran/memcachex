defmodule Memcache.Connection do
  use GenServer.Behaviour
  alias Memcache.Protocol

  defrecordp :state, [ :opts, :sock ]

  @spec start_link(Keyword.t) :: { :ok, pid } | { :error, term }
  def start_link(opts) do
    case :gen_server.start_link(__MODULE__, [], []) do
      { :ok, pid } ->
        opts = with_defaults(opts)
        case :gen_server.call(pid, { :connect, opts }) do
          :ok -> { :ok, pid }
          err -> { :error, err }
        end
      err -> err
    end
  end

  def execute(pid, command, args) do
    :gen_server.call(pid, { :execute, command, args })
  end


  defp with_defaults(opts) do
    opts
    |> Keyword.put_new(:port, 11211)
    |> Keyword.update!(:hostname, &if is_binary(&1), do: String.to_char_list!(&1), else: &1)
  end

  def init([]) do
    { :ok, state() }
  end

  def handle_call({ :connect, opts }, _from, s) do
    sock_opts = [ { :active, false }, { :packet, :raw },  :binary ]

    case :gen_tcp.connect(opts[:hostname], opts[:port], sock_opts) do
      { :ok, sock } -> { :reply, :ok, state(sock: sock) }
      { :error, reason } -> { :stop, :normal, reason, s }
    end
  end

  def handle_call({ :execute, command, args }, _from, state(sock: sock) = s) do
    packet = Protocol.to_binary(command, args)
    case :gen_tcp.send(sock, packet) do
      :ok ->
        case :gen_tcp.recv(sock, 24) do
          { :ok, raw_header } ->
            header = Protocol.parse_header(raw_header)
            body_size = Protocol.total_body_size(header)
            case :gen_tcp.recv(sock, body_size) do
              { :ok, body } ->
                response = Protocol.parse_body(header, body)
                { :reply, {:ok, response}, s }
              { :error, reason } -> { :stop, :normal, reason, s }
            end
          { :error, reason } -> { :stop, :normal, reason, s }
        end
      { :error, reason } -> { :stop, :normal, reason, s }
    end
  end

  def terminate(_reason, state(sock: sock)) do
    if sock do
      :gen_tcp.close(sock)
    end
  end
end

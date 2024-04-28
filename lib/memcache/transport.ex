defmodule Memcache.Transport do
  defstruct [:transport, :sock]

  def connect(transport, host, port, sock_opts, timeout, opts)
      when transport in [:gen_tcp, :ssl] do
    ssl_opts = Keyword.get(opts, :ssl_options, [])
    sock_opts = sock_opts ++ ssl_opts

    case transport.connect(host, port, sock_opts, timeout) do
      {:ok, sock} ->
        {:ok, %__MODULE__{transport: transport, sock: sock}}

      error ->
        error
    end
  end

  def setopts(%{transport: :gen_tcp, sock: sock}, opts) do
    :inet.setopts(sock, opts)
  end

  def setopts(%{transport: :ssl, sock: sock}, opts) do
    :ssl.setopts(sock, opts)
  end

  def send(%{transport: transport, sock: sock}, data) do
    transport.send(sock, data)
  end

  def recv(%{transport: transport, sock: sock}, length) do
    transport.recv(sock, length)
  end

  def close(%{transport: transport, sock: sock}) do
    transport.close(sock)
  end
end

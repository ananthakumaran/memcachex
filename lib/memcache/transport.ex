defmodule Memcache.Transport do
  defstruct [:transport, :sock]

  def connect(:gen_tcp, host, port, sock_opts, timeout) do
    case :gen_tcp.connect(host, port, sock_opts, timeout) do
      {:ok, sock} ->
        {:ok, %__MODULE__{transport: :gen_tcp, sock: sock}}

      error ->
        error
    end
  end

  def setopts(%{transport: :gen_tcp, sock: sock}, opts) do
    :inet.setopts(sock, opts)
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

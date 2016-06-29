defmodule Memcache.Utils do
  def format_error(:tcp_closed) do
    "TCP connection closed"
  end

  def format_error(:closed) do
    "the connection to Memcache is closed"
  end

  def format_error(reason) do
    case :inet.format_error(reason) do
      'unknown POSIX error' -> inspect(reason)
      message -> List.to_string(message)
    end
  end
end

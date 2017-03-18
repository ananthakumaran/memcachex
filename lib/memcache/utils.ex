defmodule Memcache.Utils do
  @moduledoc false

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

  def format_host(opts) do
    "#{opts[:hostname]}:#{opts[:port]}"
  end

  def next_backoff(current, backoff_max) do
    next = round(current * 1.5)

    if backoff_max == :infinity do
      next
    else
      min(next, backoff_max)
    end
  end
end

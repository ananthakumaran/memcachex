defmodule Memcache.Connection.Pool.Worker do
  def start_link({conn_opts, opts}) do
    Memcache.Connection.start_link(conn_opts, opts)
  end
end

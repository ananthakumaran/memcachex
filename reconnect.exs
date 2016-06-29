require Logger
alias Memcache.Connection

defmodule MemcacheTest do
  def loop(pid) do
    receive do
      {:execute} ->
        Connection.execute(pid, :SET, ["hello", "world"])
        result = Connection.execute(pid, :GET, ["hello"])
        Logger.info(["result ", inspect(result)])
    end
    loop(pid)
  end
end

:timer.send_interval(1000, {:execute})

{ :ok, pid } = Connection.start_link([ hostname: "localhost" ])
MemcacheTest.loop(pid)

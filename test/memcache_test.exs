defmodule MemcacheTest do
  use ExUnit.Case
  alias Memcache.Connection

  test "commands" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    cases = [
             {:GET, ["unknown"], { :error, "Key not found" }},
             {:SET, ["hello", "world"], { :ok }},
             {:GET, ["hello"], { :ok, "world" }}
            ]

    Enum.each(cases, fn ({ command, args, response }) ->
      assert(Connection.execute(pid, command, args) == response)
    end)
  end
end

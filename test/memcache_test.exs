defmodule MemcacheTest do
  use ExUnit.Case
  alias Memcache.Connection

  test "commands" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    cases = [
             {:GET, ["unknown"], { :error, "Key not found" }},
             {:SET, ["hello", "world"], { :ok }},
             {:GET, ["hello"], { :ok, "world" }},
             {:SET, ["hello", "move on"], { :ok }},
             {:GET, ["hello"], { :ok, "move on" }},
             {:ADD, ["hello", "world"], { :error, "Key exists" }},
             {:ADD, ["add", "world"], { :ok }},
             {:DELETE, ["add"], { :ok }},
             {:REPLACE, ["add", "world"], { :error, "Key not found" }},
             {:ADD, ["add", "world"], { :ok }},
             {:REPLACE, ["add", "world"], { :ok }},
             {:DELETE, ["add"], { :ok }},
             {:DELETE, ["hello"], { :ok }},
             {:DELETE, ["unkown"], { :error, "Key not found" }},
             {:INCREMENT, ["count", 1, 5], { :ok, 5 }},
             {:INCREMENT, ["count", 1, 5], { :ok, 6 }},
             {:INCREMENT, ["count", 5, 1], { :ok, 11 }},
             {:DELETE, ["count"], { :ok }},
             {:DECREMENT, ["count", 1, 5], { :ok, 5 }},
             {:DECREMENT, ["count", 1, 5], { :ok, 4 }},
             {:DECREMENT, ["count", 6, 5], { :ok, 0 }},
             {:DELETE, ["count"], { :ok }},
             {:INCREMENT, ["count", 6, 5, 0, 0xFFFFFFFF], { :error, "Key not found" }},
             {:INCREMENT, ["count", 6, 5, 0, 0x05], { :ok, 5 }},
             {:DELETE, ["count"], { :ok }},
             {:NOOP, [], { :ok }},
             {:SET, ["name", "ananth"], { :ok }},
             {:FLUSH, [0xFFFF], { :ok }},
             {:GET, ["name"], { :ok, "ananth" }},
             {:FLUSH, [], { :ok }},
             {:GET, ["name"], { :error, "Key not found" }},
             {:QUIT, [], { :ok }},
             {:DELETE, ["count"], :closed },
            ]

    Enum.each(cases, fn ({ command, args, response }) ->
      assert(Connection.execute(pid, command, args) == response)
    end)
  end
end

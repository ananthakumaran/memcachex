defmodule MemcacheTest do
  use ExUnit.Case
  alias Memcache.Connection

  test "commands" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    cases = [
             {:FLUSH, [], { :ok }},
             {:GET, ["unknown"], { :error, "Key not found" }},
             {:SET, ["hello", "world"], { :ok }},
             {:GET, ["hello"], { :ok, "world" }},
             {:SET, ["hello", "move on"], { :ok }},
             {:GET, ["hello"], { :ok, "move on" }},
             {:GETK, ["hello"], { :ok, "hello", "move on" }},
             {:GETK, ["unknown"], { :error, "Key not found" }},
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
             {:SET, ["hello", "world"], { :ok }},
             {:INCREMENT, ["hello"], { :error, "Incr/Decr on non-numeric value"}},
             {:DELETE, ["hello"], { :ok }},
             {:DECREMENT, ["count", 1, 5], { :ok, 5 }},
             {:DECREMENT, ["count", 1, 5], { :ok, 4 }},
             {:DECREMENT, ["count", 6, 5], { :ok, 0 }},
             {:DELETE, ["count"], { :ok }},
             {:SET, ["hello", "world"], { :ok }},
             {:DECREMENT, ["hello"], { :error, "Incr/Decr on non-numeric value"}},
             {:DELETE, ["hello"], { :ok }},
             {:INCREMENT, ["count", 6, 5, 0, 0xFFFFFFFF], { :error, "Key not found" }},
             {:INCREMENT, ["count", 6, 5, 0, 0x05], { :ok, 5 }},
             {:DELETE, ["count"], { :ok }},
             {:NOOP, [], { :ok }},
             {:APPEND, ["new", "hope"], { :error, "Item not stored" }},
             {:SET, ["new", "new "], { :ok }},
             {:APPEND, ["new", "hope"], { :ok }},
             {:GET, ["new"], { :ok, "new hope"}},
             {:DELETE, ["new"], { :ok }},
             {:PREPEND, ["new", "hope"], { :error, "Item not stored"}},
             {:SET, ["new", "hope"], { :ok }},
             {:PREPEND, ["new", "new "], { :ok }},
             {:GET, ["new"], { :ok, "new hope"}},
             {:DELETE, ["new"], { :ok }},
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

  test "quiet commands" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    { :ok } = Connection.execute(pid, :FLUSH, [])
    { :ok } = Connection.execute(pid, :SET, ["new", "hope"])
    cases = [
             { [{:GETQ, ["hello"]},
                {:GETQ, ["hello"]}],
               { :ok, [{ :ok, "Key not found" },
                       { :ok, "Key not found" }] }},

             { [{:GETQ, ["new"]},
                {:GETQ, ["new"]}],
               { :ok, [{ :ok, "hope" },
                       { :ok, "hope" }] }},

             { [{:GETKQ, ["new"]},
                {:GETKQ, ["unknown"]}],
               { :ok, [{ :ok, "new", "hope" },
                       { :ok, "Key not found" }] }},

             { [{:SETQ, ["hello", "WORLD"]},
                {:GETQ, ["hello"]},
                {:SETQ, ["hello", "world"]},
                {:GETQ, ["hello"]},
                {:DELETEQ, ["hello"]},
                {:GETQ, ["hello"]}],
               { :ok, [{ :ok },
                       { :ok, "WORLD" },
                       { :ok },
                       { :ok, "world" },
                       { :ok },
                       { :ok, "Key not found" }] }},

             { [{:SETQ, ["hello", "world"]},
                {:ADDQ, ["hello", "world"]},
                {:ADDQ, ["add", "world"]},
                {:GETQ, ["add"]},
                {:DELETEQ, ["add"]},
                {:DELETEQ, ["unknown"]}],
               { :ok, [{ :ok },
                       { :error, "Key exists" },
                       { :ok },
                       { :ok, "world" },
                       { :ok },
                       { :error, "Key not found" }] }},

               { [{:INCREMENTQ, ["count", 1, 5]},
                  {:GETQ, ["count"]},
                  {:INCREMENTQ, ["count", 1, 5]},
                  {:GETQ, ["count"]},
                  {:INCREMENTQ, ["count", 5]},
                  {:GETQ, ["count"]},
                  {:DELETEQ, ["count"]},
                  {:SETQ, ["hello", "world"]},
                  {:INCREMENTQ, ["hello", 1]},
                  {:DELETEQ, ["hello"]},],
               { :ok, [{ :ok },
                       { :ok, "5" },
                       { :ok },
                       { :ok, "6" },
                       { :ok },
                       { :ok , "11"},
                       { :ok },
                       { :ok },
                       { :error, "Incr/Decr on non-numeric value"},
                       { :ok }]}},

             { [{:REPLACEQ, ["add", "world"]},
                {:ADDQ, ["add", "world"]},
                {:REPLACEQ, ["add", "new"]},
                {:GETQ, ["add"]},
                {:DELETEQ, ["add"]}],
               { :ok, [{ :error, "Key not found" },
                       { :ok },
                       { :ok },
                       { :ok, "new" },
                       { :ok }]}},

            ]

    Enum.each(cases, fn ({ commands, response }) ->
      assert(Connection.execute_quiet(pid, commands) == response)
    end)
  end

  test "misc command" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    { :ok, _stat } = Connection.execute(pid, :STAT, [])
    { :ok, _stat } = Connection.execute(pid, :STAT, ["items"])
    { :ok, _stat } = Connection.execute(pid, :STAT, ["slabs"])
    { :ok, _stat } = Connection.execute(pid, :STAT, ["settings"])
    { :ok, version } = Connection.execute(pid, :VERSION, [])
    assert  version =~ %r/\d+\.\d+\.\d+/
  end
end

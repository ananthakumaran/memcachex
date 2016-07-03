defmodule Memcache.ConnectionTest do
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
             {:GET, ["name"], { :error, "Key not found" }}
            ]

    Enum.each(cases, fn ({ command, args, response }) ->
      assert(Connection.execute(pid, command, args) == response)
    end)

    { :ok } = Connection.close(pid)
  end

  test "cas commands" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    cas_error = { :error, "Key exists" }
    cases = [
      {:FLUSH, [], [], { :ok }},
      {:GET, ["unknown"], [cas: true], { :error, "Key not found" }},
      {:SET, ["hello", "world"], [cas: true], { :ok, :cas }},
      {:SET, ["hello", "world", :cas], [cas: true], { :ok, :cas }},
      {:SET, ["hello", "another"], [], { :ok }},
      {:SET, ["hello", "world", :cas], [cas: true], cas_error},
      {:GET, ["hello"], [cas: true], { :ok, "another", :cas }},
      {:SET, ["hello", "world", :cas], [cas: true], { :ok, :cas }},
      {:SET, ["hello", "move on"], [], { :ok }},
      {:GET, ["hello"], [], { :ok, "move on" }},
      {:ADD, ["add", "world"], [cas: true], { :ok, :cas }},
      {:DELETE, ["add", :cas], [], { :ok }},
      {:ADD, ["add", "world"], [], { :ok }},
      {:DELETE, ["add", :cas], [], cas_error},
      {:REPLACE, ["add", "world"], [cas: true], { :ok, :cas }},
      {:REPLACE, ["add", "world", :cas], [], { :ok }},
      {:REPLACE, ["add", "world", :cas], [], cas_error},
      {:DELETE, ["add", :cas], [], cas_error},
      {:GET, ["add"], [cas: true], { :ok, "world", :cas }},
      {:DELETE, ["add", :cas], [], { :ok }},
      {:INCREMENT, ["count", 1, 5], [cas: true], { :ok, 5, :cas }},
      {:INCREMENT, ["count", 1, 5], [], { :ok, 6 }},
      {:INCREMENT, ["count", 5, 1, :cas], [], cas_error},
      {:DELETE, ["count"], [], { :ok }},
      {:DECREMENT, ["count", 1, 5], [cas: true], { :ok, 5, :cas }},
      {:DECREMENT, ["count", 1, 5, :cas], [], { :ok, 4 }},
      {:DECREMENT, ["count", 6, 5, :cas], [], cas_error},
      {:DELETE, ["count"], [], { :ok }},
      {:SET, ["new", "new "], [cas: true], { :ok, :cas }},
      {:APPEND, ["new", "hope", :cas], [], { :ok }},
      {:APPEND, ["new", "hope", :cas], [], cas_error},
      {:APPEND, ["new", "hope"], [cas: true], { :ok, :cas }},
      {:GET, ["new"], [], { :ok, "new hopehope"}},
      {:SET, ["new", "hope"], [cas: true], { :ok, :cas }},
      {:PREPEND, ["new", "new ", :cas], [], { :ok }},
      {:PREPEND, ["new", "new ", :cas], [], cas_error},
      {:PREPEND, ["new", "new "], [cas: true], { :ok, :cas }},
      {:FLUSH, [], [], { :ok }},
    ]

    Enum.reduce(cases, nil, fn ({ command, args, opts, response }, cas) ->
      embed_cas = fn (:cas) -> cas
        (rest) -> rest
      end
      args = Enum.map(args, embed_cas)
      case response do
        { :ok, :cas } ->
          assert { :ok, cas } = Connection.execute(pid, command, args, opts)
          cas
        { :ok, value, :cas } ->
          assert { :ok, ^value, cas } = Connection.execute(pid, command, args, opts)
          cas
        rest ->
          assert rest == Connection.execute(pid, command, args, opts)
          cas
      end
    end)

    { :ok } = Connection.close(pid)
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
                  {:INCREMENTQ, ["count", 1, 5]},
                  {:GETQ, ["count"]},
                  {:INCREMENTQ, ["count", 5]},
                  {:GETQ, ["count"]},
                  {:DELETEQ, ["count"]},
                  {:SETQ, ["hello", "world"]},
                  {:INCREMENTQ, ["hello", 1]},
                  {:DELETEQ, ["hello"]},],
               { :ok, [{ :ok },
                       { :ok },
                       { :ok, "6" },
                       { :ok },
                       { :ok , "11"},
                       { :ok },
                       { :ok },
                       { :error, "Incr/Decr on non-numeric value"},
                       { :ok }]}},

               { [{:DECREMENTQ, ["count", 1, 5]},
                  {:DECREMENTQ, ["count", 1, 5]},
                  {:GETQ, ["count"]},
                  {:DECREMENTQ, ["count", 5]},
                  {:GETQ, ["count"]},
                  {:DELETEQ, ["count"]},
                  {:SETQ, ["hello", "world"]},
                  {:DECREMENTQ, ["hello", 1]},
                  {:DELETEQ, ["hello"]},],
               { :ok, [{ :ok },
                       { :ok },
                       { :ok, "4" },
                       { :ok },
                       { :ok , "0"},
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

             { [{:DELETEQ, ["new"]},
                {:APPENDQ, ["new", "hope"]},
                {:SETQ, ["new", "new "]},
                {:APPENDQ, ["new", "hope"]},
                {:GETQ, ["new"]},
                {:DELETEQ, ["new"]},
                {:PREPENDQ, ["new", "hope"]},
                {:SETQ, ["new", "hope"]},
                {:PREPENDQ, ["new", "new "]},
                {:GETQ, ["new"]},
                {:DELETEQ, ["new"]}],
               { :ok, [{ :ok },
                       { :error, "Item not stored" },
                       { :ok },
                       { :ok },
                       { :ok, "new hope"},
                       { :ok },
                       { :error, "Item not stored"},
                       { :ok },
                       { :ok },
                       { :ok, "new hope"},
                       { :ok }]}}

            ]

    Enum.each(cases, fn ({ commands, response }) ->
      assert(Connection.execute_quiet(pid, commands) == response)
    end)

    { :ok } = Connection.close(pid)
  end

  test "misc commands" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    { :ok, _stat } = Connection.execute(pid, :STAT, [])
    { :ok, _stat } = Connection.execute(pid, :STAT, ["items"])
    { :ok, _stat } = Connection.execute(pid, :STAT, ["slabs"])
    { :ok, _stat } = Connection.execute(pid, :STAT, ["settings"])
    { :ok, version } = Connection.execute(pid, :VERSION, [])
    assert  version =~ ~r/\d+\.\d+\.\d+/
    { :ok } = Connection.close(pid)
  end

  test "named process" do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ], [name: :memcachex])
    { :ok } = Connection.execute(:memcachex, :SET, ["hello", "world"])
    { :ok, "world" } = Connection.execute(:memcachex, :GET, ["hello"])
    { :ok } = Connection.close(pid)
  end
end

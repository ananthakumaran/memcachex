defmodule Memcache.ConnectionTest do
  @moduledoc false
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  import TestUtils
  import Memcache.Connection

  doctest Connection

  @cas_error {:error, "Key exists"}

  setup do
    {:ok, _} = Toxiproxy.reset()
    :ok
  end

  test "commands" do
    {:ok, pid} = start_link(port: 21_211, hostname: "localhost")

    cases = [
      {:FLUSH, [], {:ok}},
      # {:GET, ["unknown"], {:error, "Key not found"}},
      # {:SET, ["hello", "world"], {:ok}},
      # {:GET, ["hello"], {:ok, "world"}},
      # {:SET, ["hello", ['w', 'o', "rl", 'd']], {:ok}},
      # {:GET, ["hello"], {:ok, "world"}},
      # {:SET, ["hello", "move on"], {:ok}},
      # {:SET, [<<0x56::size(32)>>, <<0x56::size(32)>>], {:ok}},
      # {:GET, [<<0x56::size(32)>>], {:ok, <<0x56::size(32)>>}},
      # {:GET, ["hello"], {:ok, "move on"}},
      # {:GETK, ["hello"], {:ok, "hello", "move on"}},
      # {:GETK, ["unknown"], {:error, "Key not found"}},
      # {:ADD, ["hello", "world"], {:error, "Key exists"}},
      # {:ADD, ["add", "world"], {:ok}},
      # {:DELETE, ["add"], {:ok}},
      # {:REPLACE, ["add", "world"], {:error, "Key not found"}},
      # {:ADD, ["add", "world"], {:ok}},
      # {:REPLACE, ["add", "world"], {:ok}},
      # {:DELETE, ["add"], {:ok}},
      # {:DELETE, ["hello"], {:ok}},
      # {:DELETE, ["unkown"], {:error, "Key not found"}},
      # {:INCREMENT, ["count", 1, 5], {:ok, 5}},
      # {:INCREMENT, ["count", 1, 5], {:ok, 6}},
      # {:INCREMENT, ["count", 5, 1], {:ok, 11}},
      # {:DELETE, ["count"], {:ok}},
      # {:SET, ["hello", "world"], {:ok}},
      # {:INCREMENT, ["hello"], {:error, "Incr/Decr on non-numeric value"}},
      # {:DELETE, ["hello"], {:ok}},
      # {:DECREMENT, ["count", 1, 5], {:ok, 5}},
      # {:DECREMENT, ["count", 1, 5], {:ok, 4}},
      # {:DECREMENT, ["count", 6, 5], {:ok, 0}},
      # {:DELETE, ["count"], {:ok}},
      # {:SET, ["hello", "world"], {:ok}},
      # {:DECREMENT, ["hello"], {:error, "Incr/Decr on non-numeric value"}},
      # {:DELETE, ["hello"], {:ok}},
      # {:INCREMENT, ["count", 6, 5, 0, 0xFFFFFFFF], {:error, "Key not found"}},
      # {:INCREMENT, ["count", 6, 5, 0, 0x05], {:ok, 5}},
      # {:DELETE, ["count"], {:ok}},
      # {:NOOP, [], {:ok}},
      # {:APPEND, ["new", "hope"], {:error, "Item not stored"}},
      # {:SET, ["new", "new "], {:ok}},
      # {:APPEND, ["new", "hope"], {:ok}},
      # {:GET, ["new"], {:ok, "new hope"}},
      # {:DELETE, ["new"], {:ok}},
      # {:PREPEND, ["new", "hope"], {:error, "Item not stored"}},
      # {:SET, ["new", "hope"], {:ok}},
      # {:PREPEND, ["new", "new "], {:ok}},
      # {:GET, ["new"], {:ok, "new hope"}},
      # {:DELETE, ["new"], {:ok}},
      # {:SET, ["name", "ananth"], {:ok}},
      # {:FLUSH, [0xFFFF], {:ok}},
      # {:GET, ["name"], {:ok, "ananth"}},
      # {:FLUSH, [], {:ok}},
      # {:GET, ["name"], {:error, "Key not found"}},
      {:SET, ["hello", "world", 0, 0], {:ok}},
      {:GET, ["hello"], {:ok, "world"}},
      {:SET, ["hello", "world", 0, 0], [flags: [:serialize]], {:ok}},
      {:GET, ["hello"], [flags: [:serialize]], {:ok, "world"}},
      {:SET, ["hello", "world", 0, 0], [flags: [:serialize, :compressed]], {:ok}},
      {:GET, ["hello"], {:ok, "world"}}
    ]

    Enum.each(cases, fn
      {command, args, response} ->
        assert(execute(pid, command, args) == response)
      {command, args, opts, response} ->
        assert(execute(pid, command, args, opts) == response)
    end)

    {:ok} = close(pid)
  end

  test "cas commands" do
    {:ok, pid} = start_link(port: 21_211, hostname: "localhost")

    cases = [
      {:FLUSH, [], [], {:ok}},
      {:GET, ["unknown"], [cas: true], {:error, "Key not found"}},
      {:SET, ["hello", "world"], [cas: true], {:ok, :cas}},
      {:SET, ["hello", "world", :cas], [cas: true], {:ok, :cas}},
      {:SET, ["hello", "another"], [], {:ok}},
      {:SET, ["hello", "world", :cas], [cas: true], @cas_error},
      {:GET, ["hello"], [cas: true], {:ok, "another", :cas}},
      {:SET, ["hello", "world", :cas], [cas: true], {:ok, :cas}},
      {:SET, ["hello", "move on", :cas], [], {:ok}},
      {:GET, ["hello"], [], {:ok, "move on"}},
      {:ADD, ["add", "world"], [cas: true], {:ok, :cas}},
      {:DELETE, ["add", :cas], [], {:ok}},
      {:ADD, ["add", "world"], [], {:ok}},
      {:DELETE, ["add", :cas], [], @cas_error},
      {:REPLACE, ["add", "world"], [cas: true], {:ok, :cas}},
      {:REPLACE, ["add", "world", :cas], [], {:ok}},
      {:REPLACE, ["add", "world", :cas], [], @cas_error},
      {:DELETE, ["add", :cas], [], @cas_error},
      {:GET, ["add"], [cas: true], {:ok, "world", :cas}},
      {:DELETE, ["add", :cas], [], {:ok}},
      {:INCREMENT, ["count", 1, 5], [cas: true], {:ok, 5, :cas}},
      {:INCREMENT, ["count", 1, 5], [], {:ok, 6}},
      {:INCREMENT, ["count", 5, 1, :cas], [], @cas_error},
      {:DELETE, ["count"], [], {:ok}},
      {:DECREMENT, ["count", 1, 5], [cas: true], {:ok, 5, :cas}},
      {:DECREMENT, ["count", 1, 5, :cas], [], {:ok, 4}},
      {:DECREMENT, ["count", 6, 5, :cas], [], @cas_error},
      {:DELETE, ["count"], [], {:ok}},
      {:SET, ["new", "new "], [cas: true], {:ok, :cas}},
      {:APPEND, ["new", "hope", :cas], [], {:ok}},
      {:APPEND, ["new", "hope", :cas], [], @cas_error},
      {:APPEND, ["new", "hope"], [cas: true], {:ok, :cas}},
      {:GET, ["new"], [], {:ok, "new hopehope"}},
      {:SET, ["new", "hope"], [cas: true], {:ok, :cas}},
      {:PREPEND, ["new", "new ", :cas], [], {:ok}},
      {:PREPEND, ["new", "new ", :cas], [], @cas_error},
      {:PREPEND, ["new", "new "], [cas: true], {:ok, :cas}},
      {:FLUSH, [], [], {:ok}}
    ]

    Enum.reduce(cases, nil, fn {command, args, opts, response}, cas ->
      embed_cas = fn
        :cas -> cas
        rest -> rest
      end

      args = Enum.map(args, embed_cas)

      case response do
        {:ok, :cas} ->
          assert {:ok, cas} = execute(pid, command, args, opts)
          cas

        {:ok, value, :cas} ->
          assert {:ok, ^value, cas} = execute(pid, command, args, opts)
          cas

        rest ->
          assert rest == execute(pid, command, args, opts)
          cas
      end
    end)

    {:ok} = close(pid)
  end

  test "quiet commands" do
    {:ok, pid} = start_link(port: 21_211, hostname: "localhost")
    {:ok} = execute(pid, :FLUSH, [])
    {:ok} = execute(pid, :SET, ["new", "hope"])

    cases = [
      {[{:GETQ, ["hello"]}, {:GETQ, ["hello"]}],
       {:ok, [{:error, "Key not found"}, {:error, "Key not found"}]}},
      {[{:GETQ, ["new"]}, {:GETQ, ["new"]}], {:ok, [{:ok, "hope"}, {:ok, "hope"}]}},
      {[{:GETKQ, ["new"]}, {:GETKQ, ["unknown"]}],
       {:ok, [{:ok, "new", "hope"}, {:error, "Key not found"}]}},
      {[
         {:SETQ, ["hello", "WORLD"]},
         {:GETQ, ["hello"]},
         {:SETQ, ["hello", "world"]},
         {:GETQ, ["hello"]},
         {:DELETEQ, ["hello"]},
         {:GETQ, ["hello"]}
       ],
       {:ok, [{:ok}, {:ok, "WORLD"}, {:ok}, {:ok, "world"}, {:ok}, {:error, "Key not found"}]}},
      {[
         {:SETQ, ["hello", "WORLD"]},
         {:FLUSHQ, []},
         {:GETQ, ["hello"]},
         {:SETQ, ["hello", "world"]},
         {:FLUSHQ, [0xFFFF]},
         {:GETQ, ["hello"]},
         {:FLUSHQ, []},
         {:GETQ, ["hello"]}
       ],
       {:ok,
        [
          {:ok},
          {:ok},
          {:error, "Key not found"},
          {:ok},
          {:ok},
          {:ok, "world"},
          {:ok},
          {:error, "Key not found"}
        ]}},
      {[
         {:SETQ, ["hello", "world"]},
         {:ADDQ, ["hello", "world"]},
         {:ADDQ, ["add", "world"]},
         {:GETQ, ["add"]},
         {:DELETEQ, ["add"]},
         {:DELETEQ, ["unknown"]}
       ],
       {:ok,
        [{:ok}, {:error, "Key exists"}, {:ok}, {:ok, "world"}, {:ok}, {:error, "Key not found"}]}},
      {[
         {:INCREMENTQ, ["count", 1, 5]},
         {:INCREMENTQ, ["count", 1, 5]},
         {:GETQ, ["count"]},
         {:INCREMENTQ, ["count", 5]},
         {:GETQ, ["count"]},
         {:DELETEQ, ["count"]},
         {:SETQ, ["hello", "world"]},
         {:INCREMENTQ, ["hello", 1]},
         {:DELETEQ, ["hello"]}
       ],
       {:ok,
        [
          {:ok},
          {:ok},
          {:ok, "6"},
          {:ok},
          {:ok, "11"},
          {:ok},
          {:ok},
          {:error, "Incr/Decr on non-numeric value"},
          {:ok}
        ]}},
      {[
         {:DECREMENTQ, ["count", 1, 5]},
         {:DECREMENTQ, ["count", 1, 5]},
         {:GETQ, ["count"]},
         {:DECREMENTQ, ["count", 5]},
         {:GETQ, ["count"]},
         {:DELETEQ, ["count"]},
         {:SETQ, ["hello", "world"]},
         {:DECREMENTQ, ["hello", 1]},
         {:DELETEQ, ["hello"]}
       ],
       {:ok,
        [
          {:ok},
          {:ok},
          {:ok, "4"},
          {:ok},
          {:ok, "0"},
          {:ok},
          {:ok},
          {:error, "Incr/Decr on non-numeric value"},
          {:ok}
        ]}},
      {[
         {:REPLACEQ, ["add", "world"]},
         {:ADDQ, ["add", "world"]},
         {:REPLACEQ, ["add", "new"]},
         {:GETQ, ["add"]},
         {:DELETEQ, ["add"]}
       ], {:ok, [{:error, "Key not found"}, {:ok}, {:ok}, {:ok, "new"}, {:ok}]}},
      {[
         {:SETQ, ["new", "new "]},
         {:DELETEQ, ["new"]},
         {:APPENDQ, ["new", "hope"]},
         {:SETQ, ["new", "new "]},
         {:APPENDQ, ["new", "hope"]},
         {:GETQ, ["new"]},
         {:DELETEQ, ["new"]},
         {:PREPENDQ, ["new", "hope"]},
         {:SETQ, ["new", "hope"]},
         {:PREPENDQ, ["new", "new "]},
         {:GETQ, ["new"]},
         {:DELETEQ, ["new"]}
       ],
       {:ok,
        [
          {:ok},
          {:ok},
          {:error, "Item not stored"},
          {:ok},
          {:ok},
          {:ok, "new hope"},
          {:ok},
          {:error, "Item not stored"},
          {:ok},
          {:ok},
          {:ok, "new hope"},
          {:ok}
        ]}}
    ]

    Enum.each(cases, fn {commands, response} ->
      assert(execute_quiet(pid, commands) == response)
    end)

    {:ok} = close(pid)
  end

  test "quiet cas commands" do
    {:ok, pid} = start_link(port: 21_211, hostname: "localhost")
    {:ok} = execute(pid, :FLUSH, [])
    {:ok} = execute(pid, :SET, ["new", "hope"])

    assert {:ok, [{:ok, "hope", cas}, {:ok, "hope", cas}]} =
             execute_quiet(pid, [{:GETQ, ["new"], [cas: true]}, {:GETQ, ["new"], [cas: true]}])

    assert {:ok, [{:ok, cas}, @cas_error]} =
             execute_quiet(pid, [
               {:SET, ["new", "hope", cas], [cas: true]},
               {:SETQ, ["new", "hope", cas]}
             ])

    assert {:ok, [@cas_error, {:ok}, {:error, "Key not found"}, {:ok}, {:ok, "hope", cas}]} =
             execute_quiet(pid, [
               {:DELETEQ, ["new", 1492]},
               {:DELETEQ, ["new", cas]},
               {:GETQ, ["new"]},
               {:SETQ, ["new", "hope"]},
               {:GETQ, ["new"], [cas: true]}
             ])

    assert {:ok, [{:ok}, {:error, "Key exists"}, {:ok, _cas}, {:ok}]} =
             execute_quiet(pid, [
               {:SETQ, ["new", "world", cas]},
               {:ADDQ, ["new", "world"]},
               {:ADD, ["add", "world"], [cas: true]},
               {:DELETEQ, ["add"]}
             ])

    assert {:ok, [{:ok}, {:ok, 6, cas}]} =
             execute_quiet(pid, [
               {:INCREMENTQ, ["count", 1, 5]},
               {:INCREMENT, ["count", 1, 5], [cas: true]}
             ])

    assert {:ok, [{:ok}, {:ok, "7"}, @cas_error, {:ok, "7"}, {:ok}, {:ok, "12"}, {:ok}]} =
             execute_quiet(pid, [
               {:INCREMENTQ, ["count", 1, 5, cas]},
               {:GETQ, ["count"]},
               {:INCREMENTQ, ["count", 1, 5, cas]},
               {:GETQ, ["count"]},
               {:INCREMENTQ, ["count", 5]},
               {:GETQ, ["count"]},
               {:DELETEQ, ["count"]}
             ])

    assert {:ok, [{:ok}, {:ok, 4, cas}]} =
             execute_quiet(pid, [
               {:DECREMENTQ, ["count", 1, 5]},
               {:DECREMENT, ["count", 1, 5], [cas: true]}
             ])

    assert {:ok, [{:ok}, {:ok, "3"}, @cas_error, {:ok, "3"}, {:ok}, {:ok, "0"}, {:ok}]} ==
             execute_quiet(pid, [
               {:DECREMENTQ, ["count", 1, 5, cas]},
               {:GETQ, ["count"]},
               {:DECREMENTQ, ["count", 1, 5, cas]},
               {:GETQ, ["count"]},
               {:DECREMENTQ, ["count", 5]},
               {:GETQ, ["count"]},
               {:DELETEQ, ["count"]}
             ])

    assert {:ok, [{:error, "Key not found"}, {:ok}, {:ok, cas}]} =
             execute_quiet(pid, [
               {:REPLACEQ, ["add", "world"]},
               {:ADDQ, ["add", "world"]},
               {:REPLACE, ["add", "world"], [cas: true]}
             ])

    assert {:ok, [{:ok}, {:ok, "world"}, @cas_error, {:ok, "world"}, {:ok}]} ==
             execute_quiet(pid, [
               {:REPLACEQ, ["add", "world", cas]},
               {:GETQ, ["add"]},
               {:REPLACEQ, ["add", "new", cas]},
               {:GETQ, ["add"]},
               {:DELETEQ, ["add"]}
             ])

    assert {:ok, [{:ok}, {:ok, casa}, {:ok}, {:ok, casp}]} =
             execute_quiet(pid, [
               {:SETQ, ["a", "new"]},
               {:APPEND, ["a", " "], [cas: true]},
               {:SETQ, ["p", "hope"]},
               {:PREPEND, ["p", " "], [cas: true]}
             ])

    assert {:ok,
            [
              {:ok},
              {:ok, "new hope"},
              @cas_error,
              {:ok, "new hope"},
              {:ok},
              {:ok, "new hope"},
              @cas_error,
              {:ok, "new hope"},
              {:ok},
              {:ok}
            ]} ==
             execute_quiet(pid, [
               {:APPENDQ, ["a", "hope", casa]},
               {:GETQ, ["a"]},
               {:APPENDQ, ["a", "hope", casa]},
               {:GETQ, ["a"]},
               {:PREPENDQ, ["p", "new", casp]},
               {:GETQ, ["p"]},
               {:PREPENDQ, ["p", "new", casp]},
               {:GETQ, ["p"]},
               {:DELETEQ, ["a"]},
               {:DELETEQ, ["p"]}
             ])

    {:ok} = close(pid)
  end

  test "misc commands" do
    {:ok, pid} = start_link(port: 21_211, hostname: "localhost")
    {:ok, _stat} = execute(pid, :STAT, [])
    {:ok, _stat} = execute(pid, :STAT, ["items"])
    {:ok, _stat} = execute(pid, :STAT, ["slabs"])
    {:ok, _stat} = execute(pid, :STAT, ["settings"])
    {:ok, version} = execute(pid, :VERSION, [])
    assert version =~ ~r/\d+\.\d+\.\d+/
    {:ok} = close(pid)
  end

  test "named process" do
    {:ok, pid} = start_link([port: 21_211, hostname: "localhost"], name: :memcachex)
    {:ok} = execute(:memcachex, :SET, ["hello", "world"])
    {:ok, "world"} = execute(:memcachex, :GET, ["hello"])
    {:ok} = close(pid)
  end

  test "continue if auth is not supported" do
    assert capture_log(fn ->
             {:ok, pid} = start_link(port: 21_211, auth: {:plain, "user", "pass"})
             :timer.sleep(100)
             {:ok} = close(pid)
           end) =~ "Authentication not required"
  end

  test "reconnects automatically" do
    {:ok, pid} = start_link(port: 21_211)
    down("memcache")
    :timer.sleep(100)
    up("memcache")
    :timer.sleep(1000)
    {:ok} = execute(pid, :SET, ["hello", "world"])
    {:ok, "world"} = execute(pid, :GET, ["hello"])
    {:ok} = close(pid)
  end

  test "always responds back to client" do
    {:ok, pid} = start_link(port: 21_211)
    assert {:ok} = execute(pid, :SET, ["hello", "world"])

    pids =
      start_hammering(
        fn ->
          assert_value_or_error({:ok}, execute(pid, :SET, ["hello", "world"]))
          assert_value_or_error({:ok, "world"}, execute(pid, :GET, ["hello"]))
        end,
        8
      )

    down("memcache")
    :timer.sleep(100)
    up("memcache")
    :timer.sleep(1000)
    stop_hammering(pids)
    {:ok} = close(pid)
  end

  defp assert_value_or_error(value, value), do: true
  defp assert_value_or_error(_value, {:error, _}), do: true

  defp assert_value_or_error(value, actual) do
    flunk("Expected #{inspect(value)} or {:error, closed}\n but got #{inspect(actual)}")
  end

  @tag :authentication
  test "fail on unsupported auth type" do
    assert_exit(
      fn ->
        {:ok, pid} = start_link(port: 9494, auth: {:ldap, "user@example.com", "pass"})
        :timer.sleep(100)
        {:ok} = close(pid)
      end,
      ~r/only supports :plain/
    )
  end

  @tag :authentication
  test "plain auth" do
    {:ok, pid} = start_link(port: 9494, auth: {:plain, "user@example.com", "pass"})
    {:ok} = execute(pid, :NOOP, [])
    {:ok} = close(pid)
  end

  @tag :authentication
  test "reconnects automatically with auth" do
    {:ok, pid} = start_link(port: 9494, auth: {:plain, "user@example.com", "pass"})
    down("memcache_sasl")
    :timer.sleep(100)
    up("memcache_sasl")
    :timer.sleep(1000)
    {:ok} = execute(pid, :SET, ["hello", "world"])
    {:ok, "world"} = execute(pid, :GET, ["hello"])
    {:ok} = close(pid)
  end

  @tag :authentication
  test "invalid password" do
    assert_exit(
      fn ->
        {:ok, pid} = start_link(port: 9494, auth: {:plain, "user@example.com", "ps"})
        :timer.sleep(100)
        {:ok} = close(pid)
      end,
      ~r/auth.*not.*successful/i
    )
  end
end

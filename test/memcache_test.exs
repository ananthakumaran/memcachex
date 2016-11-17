defmodule MemcacheTest do
  use ExUnit.Case
  require IEx

  doctest Memcache

  setup do
    Memcache.flush
    Application.put_env(:memcachex, :namespace, nil)
    Application.put_env(:memcachex, :ttl, 0)
    Application.put_env(:memcachex, :coder, {Memcache.Coder.Raw, []})
    # IEx.pry
    :ok
  end

  def append_prepend do
    assert { :ok } == Memcache.set("hello", "world")
    assert { :ok } == Memcache.append("hello", "!")
    assert { :ok, "world!" } == Memcache.get("hello")
    assert { :ok } == Memcache.prepend("hello", "!")
    assert { :ok, "!world!" } == Memcache.get("hello")
    cas_error = { :error, "Key exists" }

    assert { :ok, cas } = Memcache.set("new", "new ", [cas: true])
    assert { :ok } == Memcache.append_cas("new", "hope", cas)
    assert cas_error == Memcache.append_cas("new", "hope", cas)
    assert { :ok, _cas } = Memcache.append("new", "hope", [cas: true])
    assert { :ok, "new hopehope"} == Memcache.get("new")
    assert { :ok, cas } = Memcache.set("new", "hope", [cas: true])
    assert { :ok } == Memcache.prepend_cas("new", "new ", cas)
    assert cas_error == Memcache.prepend_cas("new", "new ", cas)
    assert { :ok, _cas } = Memcache.prepend("new", "new ", [cas: true])
  end

  def common do
    assert { :ok } = Memcache.flush
    assert { :ok } == Memcache.set("hello", "world")
    assert { :ok, "world" } == Memcache.get("hello")
    assert { :error, "Key exists" } == Memcache.add("hello", "world")
    assert { :ok } == Memcache.replace("hello", "again")
    assert { :ok } == Memcache.delete("hello")
    assert { :error, "Key not found" } == Memcache.replace("hello", "world")
    assert { :error, "Key not found" } == Memcache.get("hello")
    assert { :error, "Key not found" } == Memcache.delete("hello")
    assert { :ok } == Memcache.add("hello", "world")
    assert { :ok, 3 } == Memcache.incr("count", by: 5, default: 3)
    assert { :ok, 8 } == Memcache.incr("count", by: 5)
    assert { :ok, 3 } == Memcache.decr("count", by: 5)
    assert { :ok } == Memcache.delete("count")
    assert { :ok, 0 } == Memcache.decr("count", by: 5, default: 0)
    assert { :ok, 5 } == Memcache.incr("count", by: 5)
    assert { :ok, 4 } == Memcache.decr("count")
    assert { :ok, 2 } == Memcache.decr("count", by: 2)
    assert { :ok, _hash } = Memcache.stat
    assert { :ok, _settings } = Memcache.stat("settings")
    assert { :ok, _version } = Memcache.version

    cas_error = { :error, "Key exists" }
    assert { :ok } == Memcache.flush
    assert { :error, "Key not found" } == Memcache.get("unknown", [cas: true])
    assert { :ok, cas } = Memcache.set("hello", "world", [cas: true])
    assert is_integer(cas)
    assert { :ok, cas } = Memcache.set_cas("hello", "world", cas, [cas: true])
    assert { :ok } == Memcache.set("hello", "another")
    assert cas_error == Memcache.set_cas("hello", "world", cas, [cas: true])
    assert { :ok, "another", cas } = Memcache.get("hello", [cas: true])
    assert { :ok, _cas } = Memcache.set_cas("hello", "world", cas, [cas: true])
    assert { :ok } == Memcache.set("hello", "move on")
    assert { :ok, "move on" } == Memcache.get("hello")
    assert { :ok, cas } = Memcache.add("add", "world", [cas: true])
    assert { :ok } == Memcache.delete_cas("add", cas)
    assert { :ok } == Memcache.add("add", "world")
    assert cas_error == Memcache.delete_cas("add", cas)
    assert { :ok, cas } = Memcache.replace("add", "world", [cas: true])
    assert { :ok } == Memcache.replace_cas("add", "world", cas)
    assert cas_error == Memcache.replace_cas("add", "world", cas)
    assert cas_error == Memcache.delete_cas("add", cas)
    assert { :ok, "world", cas } = Memcache.get("add", [cas: true])
    assert { :ok } == Memcache.delete_cas("add", cas)
    assert { :ok, 5, cas } = Memcache.incr("count", [by: 1, default: 5, cas: true])
    assert { :ok, 6 } == Memcache.incr("count", [by: 1, default: 5])
    assert cas_error == Memcache.incr_cas("count", cas, [by: 5, default: 1])
    assert { :ok } == Memcache.delete("count")
    assert { :ok, 5, cas } = Memcache.decr("count", [by: 1, default: 5, cas: true])
    assert { :ok, 4 } == Memcache.decr_cas("count", cas, [by: 1, default: 5])
    assert cas_error == Memcache.decr_cas("count", cas, [by: 6, default: 5])
    assert { :ok } == Memcache.delete("count")

    assert { :ok } = Memcache.noop
    assert { :ok } = Memcache.flush
  end

  test "commands" do
    common
    append_prepend
    # Now test namespace
    Application.put_env(:memcachex, :namespace, "nspace")
    common
    append_prepend
  end

  test "cas" do
    assert { :ok } == Memcache.set("counter", "0")
    increment = fn () ->
      Enum.each(1..100, fn (_) ->
        Memcache.cas("counter", &(Integer.to_string(String.to_integer(&1) + 1)))
      end)
    end
    task_a = Task.async(increment)
    task_b = Task.async(increment)
    task_c = Task.async(increment)
    Task.await(task_a)
    Task.await(task_b)
    Task.await(task_c)

    assert { :ok, "300" } == Memcache.get("counter")
  end

  test "expire" do
    assert { :ok } == Memcache.set("set", "world", ttl: 1)
    assert { :ok } == Memcache.set("replace", "world")
    assert { :ok } == Memcache.replace("replace", "world", ttl: 1)
    assert { :ok } == Memcache.add("add", "world", ttl: 1)
    assert { :ok, 5 } == Memcache.incr("incr", default: 5, ttl: 1)
    assert { :ok, 5 } == Memcache.decr("decr", default: 5, ttl: 1)

    :timer.sleep(2000)

    assert { :error, "Key not found" } == Memcache.get("set")
    assert { :error, "Key not found" } == Memcache.get("replace")
    assert { :error, "Key not found" } == Memcache.get("add")
    assert { :error, "Key not found" } == Memcache.get("incr")
    assert { :error, "Key not found" } == Memcache.get("decr")

    assert { :ok } == Memcache.set("hello", "world")
    assert { :ok } == Memcache.flush(ttl: 2)
    assert { :ok, "world" } == Memcache.get("hello")

    :timer.sleep(3000)

    assert { :error, "Key not found" } == Memcache.get("hello")
  end

  test "default ttl" do
    Application.put_env(:memcachex, :ttl, 1)

    assert { :ok } == Memcache.set("set", "world")
    assert { :ok } == Memcache.set("replace", "world")
    assert { :ok } == Memcache.replace("replace", "world")
    assert { :ok } == Memcache.add("add", "world")
    assert { :ok, 5 } == Memcache.incr("incr", default: 5)
    assert { :ok, 5 } == Memcache.decr("decr", default: 5)

    :timer.sleep(2000)

    assert { :error, "Key not found" } == Memcache.get("set")
    assert { :error, "Key not found" } == Memcache.get("replace")
    assert { :error, "Key not found" } == Memcache.get("add")
    assert { :error, "Key not found" } == Memcache.get("incr")
    assert { :error, "Key not found" } == Memcache.get("decr")
  end

  test "erlang coder" do
    Application.put_env(:memcachex, :coder, {Memcache.Coder.Erlang, []})
    common

    assert { :ok } == Memcache.set("hello", ["list", 1])
    assert { :ok, ["list", 1] } == Memcache.get("hello")

    Application.put_env(:memcachex, :coder, {Memcache.Coder.Erlang, [compressed: 9]})
    assert { :ok } == Memcache.set("hello", ["list", 1])
    assert { :ok, ["list", 1] } == Memcache.get("hello")
  end

  test "json coder" do
    Application.put_env(:memcachex, :coder, {Memcache.Coder.JSON, []})
    common

    assert { :ok } == Memcache.set("hello", ["list", 1])
    assert { :ok, ["list", 1] } == Memcache.get("hello")
    assert { :ok } == Memcache.set("hello", %{ "a" => 1 })
    assert { :ok, %{ "a" => 1 } } == Memcache.get("hello")

    Application.put_env(:memcachex, :coder, {Memcache.Coder.JSON, [keys: :atoms]})
    assert { :ok } == Memcache.set("hello", %{hello: "world"})
    assert { :ok, %{hello: "world"} } == Memcache.get("hello")
  end

  test "zip coder" do
    Application.put_env(:memcachex, :coder, {Memcache.Coder.ZIP, []})
    common
  end
end

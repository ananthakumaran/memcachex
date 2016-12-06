defmodule Memcache.PoolTest do
  use ExUnit.Case, async: false
  alias Memcache.Pool

  def append_prepend(pid) do
    assert { :ok } = Pool.flush(pid)
    assert { :ok } == Pool.set(pid, "hello", "world")
    assert { :ok } == Pool.append(pid, "hello", "!")
    assert { :ok, "world!" } == Pool.get(pid, "hello")
    assert { :ok } == Pool.prepend(pid, "hello", "!")
    assert { :ok, "!world!" } == Pool.get(pid, "hello")
    cas_error = { :error, "Key exists" }

    assert { :ok, cas } = Pool.set(pid, "new", "new ", [cas: true])
    assert { :ok } == Pool.append_cas(pid, "new", "hope", cas)
    assert cas_error == Pool.append_cas(pid, "new", "hope", cas)
    assert { :ok, _cas } = Pool.append(pid, "new", "hope", [cas: true])
    assert { :ok, "new hopehope"} == Pool.get(pid, "new")
    assert { :ok, cas } = Pool.set(pid, "new", "hope", [cas: true])
    assert { :ok } == Pool.prepend_cas(pid, "new", "new ", cas)
    assert cas_error == Pool.prepend_cas(pid, "new", "new ", cas)
    assert { :ok, _cas } = Pool.prepend(pid, "new", "new ", [cas: true])
    assert { :ok } = Pool.flush(pid)
  end

  def common(pid) do
    assert { :ok } = Pool.flush(pid)
    assert { :ok } == Pool.set(pid, "hello", "world")
    assert { :ok, "world" } == Pool.get(pid, "hello")
    assert { :error, "Key exists" } == Pool.add(pid, "hello", "world")
    assert { :ok } == Pool.replace(pid, "hello", "again")
    assert { :ok } == Pool.delete(pid, "hello")
    assert { :error, "Key not found" } == Pool.replace(pid, "hello", "world")
    assert { :error, "Key not found" } == Pool.get(pid, "hello")
    assert { :error, "Key not found" } == Pool.delete(pid, "hello")
    assert { :ok } == Pool.add(pid, "hello", "world")
    assert { :ok, 3 } == Pool.incr(pid, "count", by: 5, default: 3)
    assert { :ok, 8 } == Pool.incr(pid, "count", by: 5)
    assert { :ok, 3 } == Pool.decr(pid, "count", by: 5)
    assert { :ok } == Pool.delete(pid, "count")
    assert { :ok, 0 } == Pool.decr(pid, "count", by: 5, default: 0)
    assert { :ok, 5 } == Pool.incr(pid, "count", by: 5)
    assert { :ok, 4 } == Pool.decr(pid, "count")
    assert { :ok, 2 } == Pool.decr(pid, "count", by: 2)
    assert { :ok, _hash } = Pool.stat(pid)
    assert { :ok, _settings } = Pool.stat(pid, "settings")
    assert { :ok, _version } = Pool.version(pid)

    cas_error = { :error, "Key exists" }
    assert { :ok } == Pool.flush(pid)
    assert { :error, "Key not found" } == Pool.get(pid, "unknown", [cas: true])
    assert { :ok, cas } = Pool.set(pid, "hello", "world", [cas: true])
    assert is_integer(cas)
    assert { :ok, cas } = Pool.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok } == Pool.set(pid, "hello", "another")
    assert cas_error == Pool.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok, "another", cas } = Pool.get(pid, "hello", [cas: true])
    assert { :ok, _cas } = Pool.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok } == Pool.set(pid, "hello", "move on")
    assert { :ok, "move on" } == Pool.get(pid, "hello")
    assert { :ok, cas } = Pool.add(pid, "add", "world", [cas: true])
    assert { :ok } == Pool.delete_cas(pid, "add", cas)
    assert { :ok } == Pool.add(pid, "add", "world")
    assert cas_error == Pool.delete_cas(pid, "add", cas)
    assert { :ok, cas } = Pool.replace(pid, "add", "world", [cas: true])
    assert { :ok } == Pool.replace_cas(pid, "add", "world", cas)
    assert cas_error == Pool.replace_cas(pid, "add", "world", cas)
    assert cas_error == Pool.delete_cas(pid, "add", cas)
    assert { :ok, "world", cas } = Pool.get(pid, "add", [cas: true])
    assert { :ok } == Pool.delete_cas(pid, "add", cas)
    assert { :ok, 5, cas } = Pool.incr(pid, "count", [by: 1, default: 5, cas: true])
    assert { :ok, 6 } == Pool.incr(pid, "count", [by: 1, default: 5])
    assert cas_error == Pool.incr_cas(pid, "count", cas, [by: 5, default: 1])
    assert { :ok } == Pool.delete(pid, "count")
    assert { :ok, 5, cas } = Pool.decr(pid, "count", [by: 1, default: 5, cas: true])
    assert { :ok, 4 } == Pool.decr_cas(pid, "count", cas, [by: 1, default: 5])
    assert cas_error == Pool.decr_cas(pid, "count", cas, [by: 6, default: 5])
    assert { :ok } == Pool.delete(pid, "count")
    assert { :ok } == Pool.flush(pid)

    assert { :ok } = Pool.noop(pid)
    assert { :ok } = Pool.flush(pid)
  end

  test "commands" do
    assert { :ok, pid } = Pool.start_link()
    common(pid)
    append_prepend(pid)
    assert { :ok } = Pool.stop(pid)
  end

  test "cas" do
    assert { :ok, pid } = Pool.start_link()
    assert { :ok } == Pool.set(pid, "counter", "0")
    increment = fn () ->
      Enum.each(1..100, fn (_) ->
        Pool.cas(pid, "counter", &(Integer.to_string(String.to_integer(&1) + 1)))
      end)
    end
    task_a = Task.async(increment)
    task_b = Task.async(increment)
    task_c = Task.async(increment)
    Task.await(task_a)
    Task.await(task_b)
    Task.await(task_c)

    assert { :ok, "300" } == Pool.get(pid, "counter")
    assert { :ok } = Pool.stop(pid)
  end

  test "expire" do
    assert { :ok, pid } = Pool.start_link()
    assert { :ok } == Pool.flush(pid)

    assert { :ok } == Pool.set(pid, "set", "world", ttl: 1)
    assert { :ok } == Pool.set(pid, "replace", "world")
    assert { :ok } == Pool.replace(pid, "replace", "world", ttl: 1)
    assert { :ok } == Pool.add(pid, "add", "world", ttl: 1)
    assert { :ok, 5 } == Pool.incr(pid, "incr", default: 5, ttl: 1)
    assert { :ok, 5 } == Pool.decr(pid, "decr", default: 5, ttl: 1)

    :timer.sleep(2000)

    assert { :error, "Key not found" } == Pool.get(pid, "set")
    assert { :error, "Key not found" } == Pool.get(pid, "replace")
    assert { :error, "Key not found" } == Pool.get(pid, "add")
    assert { :error, "Key not found" } == Pool.get(pid, "incr")
    assert { :error, "Key not found" } == Pool.get(pid, "decr")

    assert { :ok } == Pool.set(pid, "hello", "world")
    assert { :ok } == Pool.flush(pid, ttl: 2)
    assert { :ok, "world" } == Pool.get(pid, "hello")

    :timer.sleep(3000)

    assert { :error, "Key not found" } == Pool.get(pid, "hello")
    assert { :ok } = Pool.stop(pid)
  end

  test "namespace" do
    assert { :ok, namespaced } = Pool.start_link([namespace: "app"])
    assert { :ok, pid } = Pool.start_link()
    assert { :ok } = Pool.flush(pid)
    assert { :ok } == Pool.set(namespaced, "hello", "world")
    assert { :error, "Key not found" } == Pool.get(pid, "hello")
    assert { :ok, "world" } == Pool.get(namespaced, "hello")
    assert { :ok, "world" } == Pool.get(pid, "app:hello")
    assert { :ok } == Pool.delete(namespaced, "hello")
    assert { :error, "Key not found" } == Pool.get(namespaced, "hello")
    assert { :ok } = Pool.flush(pid)
    assert { :ok } = Pool.stop(pid)

    common(namespaced)
    append_prepend(namespaced)
    assert { :ok } = Pool.stop(namespaced)
  end

  test "default ttl" do
    assert { :ok, pid } = Pool.start_link([ttl: 1])
    assert { :ok } == Pool.flush(pid)

    assert { :ok } == Pool.set(pid, "set", "world")
    assert { :ok } == Pool.set(pid, "replace", "world")
    assert { :ok } == Pool.replace(pid, "replace", "world")
    assert { :ok } == Pool.add(pid, "add", "world")
    assert { :ok, 5 } == Pool.incr(pid, "incr", default: 5)
    assert { :ok, 5 } == Pool.decr(pid, "decr", default: 5)

    :timer.sleep(2000)

    assert { :error, "Key not found" } == Pool.get(pid, "set")
    assert { :error, "Key not found" } == Pool.get(pid, "replace")
    assert { :error, "Key not found" } == Pool.get(pid, "add")
    assert { :error, "Key not found" } == Pool.get(pid, "incr")
    assert { :error, "Key not found" } == Pool.get(pid, "decr")

    common(pid)
    assert { :ok } = Pool.stop(pid)
  end

  test "erlang coder" do
    assert { :ok, pid } = Pool.start_link([coder: Memcache.Coder.Erlang])
    common(pid)

    assert { :ok } == Pool.set(pid, "hello", ["list", 1])
    assert { :ok, ["list", 1] } == Pool.get(pid, "hello")
    assert { :ok } = Pool.stop(pid)

    assert { :ok, pid } = Pool.start_link([coder: {Memcache.Coder.Erlang, [compressed: 9]}])
    assert { :ok } == Pool.set(pid, "hello", ["list", 1])
    assert { :ok, ["list", 1] } == Pool.get(pid, "hello")
    assert { :ok } = Pool.stop(pid)
  end

  test "json coder" do
    assert { :ok, pid } = Pool.start_link([coder: Memcache.Coder.JSON])
    common(pid)

    assert { :ok } == Pool.set(pid, "hello", ["list", 1])
    assert { :ok, ["list", 1] } == Pool.get(pid, "hello")
    assert { :ok } == Pool.set(pid, "hello", %{ "a" => 1 })
    assert { :ok, %{ "a" => 1 } } == Pool.get(pid, "hello")
    assert { :ok } = Pool.stop(pid)

    assert { :ok, pid } = Pool.start_link([coder: {Memcache.Coder.JSON, [keys: :atoms]}])
    assert { :ok } == Pool.set(pid, "hello", %{hello: "world"})
    assert { :ok, %{hello: "world"} } == Pool.get(pid, "hello")
    assert { :ok } = Pool.stop(pid)
  end

  test "zip coder" do
    assert { :ok, pid } = Pool.start_link([coder: Memcache.Coder.ZIP])
    common(pid)
    assert { :ok } = Pool.stop(pid)
  end
end

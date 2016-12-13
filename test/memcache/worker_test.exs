defmodule Memcache.WorkerTest do
  use ExUnit.Case, async: false
  import TestUtils
  alias Memcache.Worker

  doctest Memcache.Worker

  def append_prepend(pid) do
    assert { :ok } = Worker.flush(pid)
    assert { :ok } == Worker.set(pid, "hello", "world")
    assert { :ok } == Worker.append(pid, "hello", "!")
    assert { :ok, "world!" } == Worker.get(pid, "hello")
    assert { :ok } == Worker.prepend(pid, "hello", "!")
    assert { :ok, "!world!" } == Worker.get(pid, "hello")
    cas_error = { :error, "Key exists" }

    assert { :ok, cas } = Worker.set(pid, "new", "new ", [cas: true])
    assert { :ok } == Worker.append_cas(pid, "new", "hope", cas)
    assert cas_error == Worker.append_cas(pid, "new", "hope", cas)
    assert { :ok, _cas } = Worker.append(pid, "new", "hope", [cas: true])
    assert { :ok, "new hopehope"} == Worker.get(pid, "new")
    assert { :ok, cas } = Worker.set(pid, "new", "hope", [cas: true])
    assert { :ok } == Worker.prepend_cas(pid, "new", "new ", cas)
    assert cas_error == Worker.prepend_cas(pid, "new", "new ", cas)
    assert { :ok, _cas } = Worker.prepend(pid, "new", "new ", [cas: true])
    assert { :ok } = Worker.flush(pid)
  end

  def common(pid) do
    assert { :ok } = Worker.flush(pid)
    assert { :ok } == Worker.set(pid, "hello", "world")
    assert { :ok, "world" } == Worker.get(pid, "hello")
    assert { :error, "Key exists" } == Worker.add(pid, "hello", "world")
    assert { :ok } == Worker.replace(pid, "hello", "again")
    assert { :ok } == Worker.delete(pid, "hello")
    assert { :error, "Key not found" } == Worker.replace(pid, "hello", "world")
    assert { :error, "Key not found" } == Worker.get(pid, "hello")
    assert { :error, "Key not found" } == Worker.delete(pid, "hello")
    assert { :ok } == Worker.add(pid, "hello", "world")
    assert { :ok, 3 } == Worker.incr(pid, "count", by: 5, default: 3)
    assert { :ok, 8 } == Worker.incr(pid, "count", by: 5)
    assert { :ok, 3 } == Worker.decr(pid, "count", by: 5)
    assert { :ok } == Worker.delete(pid, "count")
    assert { :ok, 0 } == Worker.decr(pid, "count", by: 5, default: 0)
    assert { :ok, 5 } == Worker.incr(pid, "count", by: 5)
    assert { :ok, 4 } == Worker.decr(pid, "count")
    assert { :ok, 2 } == Worker.decr(pid, "count", by: 2)
    assert { :ok, _hash } = Worker.stat(pid)
    assert { :ok, _settings } = Worker.stat(pid, ["settings"])
    assert { :ok, _version } = Worker.version(pid)

    cas_error = { :error, "Key exists" }
    assert { :ok } == Worker.flush(pid)
    assert { :error, "Key not found" } == Worker.get(pid, "unknown", [cas: true])
    assert { :ok, cas } = Worker.set(pid, "hello", "world", [cas: true])
    assert is_integer(cas)
    assert { :ok, cas } = Worker.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok } == Worker.set(pid, "hello", "another")
    assert cas_error == Worker.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok, "another", cas } = Worker.get(pid, "hello", [cas: true])
    assert { :ok, _cas } = Worker.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok } == Worker.set(pid, "hello", "move on")
    assert { :ok, "move on" } == Worker.get(pid, "hello")
    assert { :ok, cas } = Worker.add(pid, "add", "world", [cas: true])
    assert { :ok } == Worker.delete_cas(pid, "add", cas)
    assert { :ok } == Worker.add(pid, "add", "world")
    assert cas_error == Worker.delete_cas(pid, "add", cas)
    assert { :ok, cas } = Worker.replace(pid, "add", "world", [cas: true])
    assert { :ok } == Worker.replace_cas(pid, "add", "world", cas)
    assert cas_error == Worker.replace_cas(pid, "add", "world", cas)
    assert cas_error == Worker.delete_cas(pid, "add", cas)
    assert { :ok, "world", cas } = Worker.get(pid, "add", [cas: true])
    assert { :ok } == Worker.delete_cas(pid, "add", cas)
    assert { :ok, 5, cas } = Worker.incr(pid, "count", [by: 1, default: 5, cas: true])
    assert { :ok, 6 } == Worker.incr(pid, "count", [by: 1, default: 5])
    assert cas_error == Worker.incr_cas(pid, "count", cas, [by: 5, default: 1])
    assert { :ok } == Worker.delete(pid, "count")
    assert { :ok, 5, cas } = Worker.decr(pid, "count", [by: 1, default: 5, cas: true])
    assert { :ok, 4 } == Worker.decr_cas(pid, "count", cas, [by: 1, default: 5])
    assert cas_error == Worker.decr_cas(pid, "count", cas, [by: 6, default: 5])
    assert { :ok } == Worker.delete(pid, "count")
    assert { :ok } == Worker.flush(pid)

    assert { :ok } = Worker.noop(pid)
    assert { :ok } = Worker.flush(pid)
  end

  test "commands" do
    assert { :ok, pid } = Worker.start_link()
    common(pid)
    append_prepend(pid)
    assert { :ok } = Worker.stop(pid)
  end

  test "cas" do
    assert { :ok, pid } = Worker.start_link()
    assert { :ok } == Worker.set(pid, "counter", "0")
    increment = fn () ->
      Enum.each(1..100, fn (_) ->
        Worker.cas(pid, "counter", &(Integer.to_string(String.to_integer(&1) + 1)))
      end)
    end
    task_a = Task.async(increment)
    task_b = Task.async(increment)
    task_c = Task.async(increment)
    Task.await(task_a)
    Task.await(task_b)
    Task.await(task_c)

    assert { :ok, "300" } == Worker.get(pid, "counter")
    assert { :ok } = Worker.stop(pid)
  end

  test "expire" do
    assert { :ok, pid } = Worker.start_link()
    assert { :ok } == Worker.flush(pid)

    assert { :ok } == Worker.set(pid, "set", "world", ttl: 1)
    assert { :ok } == Worker.set(pid, "replace", "world")
    assert { :ok } == Worker.replace(pid, "replace", "world", ttl: 1)
    assert { :ok } == Worker.add(pid, "add", "world", ttl: 1)
    assert { :ok, 5 } == Worker.incr(pid, "incr", default: 5, ttl: 1)
    assert { :ok, 5 } == Worker.decr(pid, "decr", default: 5, ttl: 1)

    :timer.sleep(2000)

    assert { :error, "Key not found" } == Worker.get(pid, "set")
    assert { :error, "Key not found" } == Worker.get(pid, "replace")
    assert { :error, "Key not found" } == Worker.get(pid, "add")
    assert { :error, "Key not found" } == Worker.get(pid, "incr")
    assert { :error, "Key not found" } == Worker.get(pid, "decr")

    assert { :ok } == Worker.set(pid, "hello", "world")
    assert { :ok } == Worker.flush(pid, ttl: 2)
    assert { :ok, "world" } == Worker.get(pid, "hello")

    :timer.sleep(3000)

    assert { :error, "Key not found" } == Worker.get(pid, "hello")
    assert { :ok } = Worker.stop(pid)
  end

  test "namespace" do
    assert { :ok, namespaced } = Worker.start_link([namespace: "app"])
    assert { :ok, pid } = Worker.start_link()
    assert { :ok } = Worker.flush(pid)
    assert { :ok } == Worker.set(namespaced, "hello", "world")
    assert { :error, "Key not found" } == Worker.get(pid, "hello")
    assert { :ok, "world" } == Worker.get(namespaced, "hello")
    assert { :ok, "world" } == Worker.get(pid, "app:hello")
    assert { :ok } == Worker.delete(namespaced, "hello")
    assert { :error, "Key not found" } == Worker.get(namespaced, "hello")
    assert { :ok } = Worker.flush(pid)
    assert { :ok } = Worker.stop(pid)

    common(namespaced)
    append_prepend(namespaced)
    assert { :ok } = Worker.stop(namespaced)
  end

  test "default ttl" do
    assert { :ok, pid } = Worker.start_link([ttl: 1])
    assert { :ok } == Worker.flush(pid)

    assert { :ok } == Worker.set(pid, "set", "world")
    assert { :ok } == Worker.set(pid, "replace", "world")
    assert { :ok } == Worker.replace(pid, "replace", "world")
    assert { :ok } == Worker.add(pid, "add", "world")
    assert { :ok, 5 } == Worker.incr(pid, "incr", default: 5)
    assert { :ok, 5 } == Worker.decr(pid, "decr", default: 5)

    :timer.sleep(2000)

    assert { :error, "Key not found" } == Worker.get(pid, "set")
    assert { :error, "Key not found" } == Worker.get(pid, "replace")
    assert { :error, "Key not found" } == Worker.get(pid, "add")
    assert { :error, "Key not found" } == Worker.get(pid, "incr")
    assert { :error, "Key not found" } == Worker.get(pid, "decr")

    common(pid)
    assert { :ok } = Worker.stop(pid)
  end

  test "server and connection are linked" do
    assert_exit(fn ->
      assert { :ok, server } = Worker.start_link()
      connection = Worker.connection_pid(server)
      Process.exit(connection, :kill)
    end, :killed)
  end

  test "erlang coder" do
    assert { :ok, pid } = Worker.start_link([coder: Memcache.Coder.Erlang])
    common(pid)

    assert { :ok } == Worker.set(pid, "hello", ["list", 1])
    assert { :ok, ["list", 1] } == Worker.get(pid, "hello")
    assert { :ok } = Worker.stop(pid)

    assert { :ok, pid } = Worker.start_link([coder: {Memcache.Coder.Erlang, [compressed: 9]}])
    assert { :ok } == Worker.set(pid, "hello", ["list", 1])
    assert { :ok, ["list", 1] } == Worker.get(pid, "hello")
    assert { :ok } = Worker.stop(pid)
  end

  test "json coder" do
    assert { :ok, pid } = Worker.start_link([coder: Memcache.Coder.JSON])
    common(pid)

    assert { :ok } == Worker.set(pid, "hello", ["list", 1])
    assert { :ok, ["list", 1] } == Worker.get(pid, "hello")
    assert { :ok } == Worker.set(pid, "hello", %{ "a" => 1 })
    assert { :ok, %{ "a" => 1 } } == Worker.get(pid, "hello")
    assert { :ok } = Worker.stop(pid)

    assert { :ok, pid } = Worker.start_link([coder: {Memcache.Coder.JSON, [keys: :atoms]}])
    assert { :ok } == Worker.set(pid, "hello", %{hello: "world"})
    assert { :ok, %{hello: "world"} } == Worker.get(pid, "hello")
    assert { :ok } = Worker.stop(pid)
  end

  test "zip coder" do
    assert { :ok, pid } = Worker.start_link([coder: Memcache.Coder.ZIP])
    common(pid)
    assert { :ok } = Worker.stop(pid)
  end
end

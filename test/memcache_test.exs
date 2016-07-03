defmodule MemcacheTest do
  use ExUnit.Case

  test "commands" do
    assert { :ok, pid } = Memcache.start_link()
    assert { :ok } == Memcache.set(pid, "hello", "world")
    assert { :ok, "world" } == Memcache.get(pid, "hello")
    assert { :error, "Key exists" } == Memcache.add(pid, "hello", "world")
    assert { :ok } == Memcache.replace(pid, "hello", "again")
    assert { :ok } == Memcache.delete(pid, "hello")
    assert { :error, "Key not found" } == Memcache.replace(pid, "hello", "world")
    assert { :error, "Key not found" } == Memcache.get(pid, "hello")
    assert { :error, "Key not found" } == Memcache.delete(pid, "hello")
    assert { :ok } == Memcache.add(pid, "hello", "world")
    assert { :ok } == Memcache.append(pid, "hello", "!")
    assert { :ok, "world!" } == Memcache.get(pid, "hello")
    assert { :ok } == Memcache.prepend(pid, "hello", "!")
    assert { :ok, "!world!" } == Memcache.get(pid, "hello")
    assert { :ok, 3 } == Memcache.incr(pid, "count", by: 5, default: 3)
    assert { :ok, 8 } == Memcache.incr(pid, "count", by: 5)
    assert { :ok, 3 } == Memcache.decr(pid, "count", by: 5)
    assert { :ok } == Memcache.delete(pid, "count")
    assert { :ok, 0 } == Memcache.decr(pid, "count", by: 5, default: 0)
    assert { :ok, 5 } == Memcache.incr(pid, "count", by: 5)
    assert { :ok, 4 } == Memcache.decr(pid, "count")
    assert { :ok, 2 } == Memcache.decr(pid, "count", by: 2)
    assert { :ok, _hash } = Memcache.stat(pid)
    assert { :ok, _settings } = Memcache.stat(pid, "settings")
    assert { :ok, _version } = Memcache.version(pid)

    cas_error = { :error, "Key exists" }
    assert { :ok } == Memcache.flush(pid)
    assert { :error, "Key not found" } == Memcache.get(pid, "unknown", [cas: true])
    assert { :ok, cas } = Memcache.set(pid, "hello", "world", [cas: true])
    assert { :ok, cas } = Memcache.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok } == Memcache.set(pid, "hello", "another")
    assert cas_error == Memcache.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok, "another", cas } = Memcache.get(pid, "hello", [cas: true])
    assert { :ok, _cas } = Memcache.set_cas(pid, "hello", "world", cas, [cas: true])
    assert { :ok } == Memcache.set(pid, "hello", "move on")
    assert { :ok, "move on" } == Memcache.get(pid, "hello")
    assert { :ok, cas } = Memcache.add(pid, "add", "world", [cas: true])
    assert { :ok } == Memcache.delete_cas(pid, "add", cas)
    assert { :ok } == Memcache.add(pid, "add", "world")
    assert cas_error == Memcache.delete_cas(pid, "add", cas)
    assert { :ok, cas } = Memcache.replace(pid, "add", "world", [cas: true])
    assert { :ok } == Memcache.replace_cas(pid, "add", "world", cas)
    assert cas_error == Memcache.replace_cas(pid, "add", "world", cas)
    assert cas_error == Memcache.delete_cas(pid, "add", cas)
    assert { :ok, "world", cas } = Memcache.get(pid, "add", [cas: true])
    assert { :ok } == Memcache.delete_cas(pid, "add", cas)
    assert { :ok, 5, cas } = Memcache.incr(pid, "count", [by: 1, default: 5, cas: true])
    assert { :ok, 6 } == Memcache.incr(pid, "count", [by: 1, default: 5])
    assert cas_error == Memcache.incr_cas(pid, "count", cas, [by: 5, default: 1])
    assert { :ok } == Memcache.delete(pid, "count")
    assert { :ok, 5, cas } = Memcache.decr(pid, "count", [by: 1, default: 5, cas: true])
    assert { :ok, 4 } == Memcache.decr_cas(pid, "count", cas, [by: 1, default: 5])
    assert cas_error == Memcache.decr_cas(pid, "count", cas, [by: 6, default: 5])
    assert { :ok } == Memcache.delete(pid, "count")
    assert { :ok, cas } = Memcache.set(pid, "new", "new ", [cas: true])
    assert { :ok } == Memcache.append_cas(pid, "new", "hope", cas)
    assert cas_error == Memcache.append_cas(pid, "new", "hope", cas)
    assert { :ok, _cas } = Memcache.append(pid, "new", "hope", [cas: true])
    assert { :ok, "new hopehope"} == Memcache.get(pid, "new")
    assert { :ok, cas } = Memcache.set(pid, "new", "hope", [cas: true])
    assert { :ok } == Memcache.prepend_cas(pid, "new", "new ", cas)
    assert cas_error == Memcache.prepend_cas(pid, "new", "new ", cas)
    assert { :ok, _cas } = Memcache.prepend(pid, "new", "new ", [cas: true])
    assert { :ok } == Memcache.flush(pid)

    assert { :ok } = Memcache.noop(pid)
    assert { :ok } = Memcache.flush(pid)
    assert { :ok } = Memcache.stop(pid)
  end

  test "cas" do
    assert { :ok, pid } = Memcache.start_link()
    assert { :ok } == Memcache.set(pid, "counter", "0")
    increment = fn () ->
      Enum.each(1..100, fn (_) ->
        Memcache.cas(pid, "counter", &(Integer.to_string(String.to_integer(&1) + 1)))
      end)
    end
    task_a = Task.async(increment)
    task_b = Task.async(increment)
    task_c = Task.async(increment)
    Task.await(task_a)
    Task.await(task_b)
    Task.await(task_c)

    assert { :ok, "300" } == Memcache.get(pid, "counter")
    assert { :ok } = Memcache.stop(pid)
  end

  test "expire" do
    assert { :ok, pid } = Memcache.start_link()
    assert { :ok } == Memcache.flush(pid)

    assert { :ok } == Memcache.set(pid, "set", "world", ttl: 1)
    assert { :ok } == Memcache.set(pid, "replace", "world")
    assert { :ok } == Memcache.replace(pid, "replace", "world", ttl: 1)
    assert { :ok } == Memcache.add(pid, "add", "world", ttl: 1)
    assert { :ok, 5 } == Memcache.incr(pid, "incr", default: 5, ttl: 1)
    assert { :ok, 5 } == Memcache.decr(pid, "decr", default: 5, ttl: 1)

    Process.sleep(2000)

    assert { :error, "Key not found" } == Memcache.get(pid, "set")
    assert { :error, "Key not found" } == Memcache.get(pid, "replace")
    assert { :error, "Key not found" } == Memcache.get(pid, "add")
    assert { :error, "Key not found" } == Memcache.get(pid, "incr")
    assert { :error, "Key not found" } == Memcache.get(pid, "decr")

    assert { :ok } == Memcache.set(pid, "hello", "world")
    assert { :ok } == Memcache.flush(pid, ttl: 2)
    assert { :ok, "world" } == Memcache.get(pid, "hello")

    Process.sleep(3000)

    assert { :error, "Key not found" } == Memcache.get(pid, "hello")
    assert { :ok } = Memcache.stop(pid)
  end
end

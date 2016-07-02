defmodule MemcacheTest do
  use ExUnit.Case

  test "commands" do
    { :ok, pid } = Memcache.start_link()
    { :ok } = Memcache.set(pid, "hello", "world")
    { :ok, "world" } = Memcache.get(pid, "hello")
    { :error, "Key exists" } = Memcache.add(pid, "hello", "world")
    { :ok } = Memcache.replace(pid, "hello", "again")
    { :ok } = Memcache.delete(pid, "hello")
    { :error, "Key not found" } = Memcache.replace(pid, "hello", "world")
    { :error, "Key not found" } = Memcache.get(pid, "hello")
    { :error, "Key not found" } = Memcache.delete(pid, "hello")
    { :ok } = Memcache.add(pid, "hello", "world")
    { :ok } = Memcache.append(pid, "hello", "!")
    { :ok, "world!" } = Memcache.get(pid, "hello")
    { :ok } = Memcache.prepend(pid, "hello", "!")
    { :ok, "!world!" } = Memcache.get(pid, "hello")
    { :ok, 3 } = Memcache.incr(pid, "count", by: 5, default: 3)
    { :ok, 8 } = Memcache.incr(pid, "count", by: 5)
    { :ok, 3 } = Memcache.decr(pid, "count", by: 5)
    { :ok } = Memcache.delete(pid, "count")
    { :ok, 0 } = Memcache.decr(pid, "count", by: 5, default: 0)
    { :ok, 5 } = Memcache.incr(pid, "count", by: 5)
    { :ok, 4 } = Memcache.decr(pid, "count")
    { :ok, 2 } = Memcache.decr(pid, "count", by: 2)
    { :ok, _hash } = Memcache.stat(pid)
    { :ok, _settings } = Memcache.stat(pid, "settings")
    { :ok, _version } = Memcache.version(pid)
    { :ok } = Memcache.noop(pid)
    { :ok } = Memcache.flush(pid)
    { :ok } = Memcache.stop(pid)
  end
end

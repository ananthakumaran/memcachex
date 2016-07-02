defmodule MemcacheTest do
  use ExUnit.Case

  test "commands" do
    { :ok, pid } = Memcache.start_link()
    { :ok } = Memcache.set(pid, "hello", "world")
    { :ok, "world" } = Memcache.get(pid, "hello")
    { :ok } = Memcache.delete(pid, "hello")
    { :error, "Key not found" } = Memcache.get(pid, "hello")
    { :error, "Key not found" } = Memcache.delete(pid, "hello")
    { :ok, _hash } = Memcache.stat(pid)
    { :ok, _settings } = Memcache.stat(pid, "settings")
    { :ok, _version } = Memcache.version(pid)
    { :ok } = Memcache.noop(pid)
    { :ok } = Memcache.flush(pid)
    { :ok } = Memcache.stop(pid)
  end
end

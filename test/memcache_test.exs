defmodule MemcacheTest do
  use ExUnit.Case

  test "commands" do
    { :ok, pid } = Memcache.start_link()
    { :ok } = Memcache.set(pid, "hello", "world")
    { :ok, "world" } = Memcache.get(pid, "hello")
    { :ok } = Memcache.stop(pid)
  end
end

defmodule Memcache.RegistryTest do
  use ExUnit.Case, async: false
  alias Memcache.Registry

  test "clears data when the process exits" do
    Registry.start_link

    pid = spawn_link(fn ->
      receive do
        :exit -> :ok
      end
    end)
    assert Registry.associate(pid, :ok) == :ok
    assert Registry.lookup(pid) == :ok
    send(pid, :exit)
    Process.sleep(50)
    assert_raise(ArgumentError, fn ->
      Registry.lookup(pid)
    end)
  end
end

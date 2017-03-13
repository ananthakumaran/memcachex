defmodule TestUtils do
  import ExUnit.Assertions
  import ExUnit.CaptureLog
  def assert_exit(task, expected_reason \\ :__none, timeout \\ 500) do
    Process.flag(:trap_exit, true)
    pid = spawn_link(fn ->
      capture_log(task)
    end)
    receive do
      {:EXIT, ^pid, reason} ->
        Process.flag(:trap_exit, false)
        unless expected_reason == :__none do
          if Regex.regex?(expected_reason) do
            assert reason =~ expected_reason
          else
            assert reason == expected_reason
          end
        end
    after timeout ->
        Process.flag(:trap_exit, false)
        flunk "Failed to exit within #{timeout}"
    end
  end

  def down(service) do
    {:ok, _} = Toxiproxy.update(%{name: service, enabled: false})
  end

  def up(service) do
    {:ok, _} = Toxiproxy.update(%{name: service, enabled: true})
  end

  def start_hammering(callback, concurrency) do
    for _i <- 1..concurrency do
      spawn_link(fn -> loop(callback) end)
    end
  end

  defp loop(callback) do
    callback.()
    receive do
      {:exit, sender} ->
        send(sender, :ok)
        :ok
    after
      0 -> loop(callback)
    end
  end

  def stop_hammering(pids) do
    for pid <- pids do
      send(pid, {:exit, self()})
      receive do
        :ok -> :ok
      end
    end
  end
end

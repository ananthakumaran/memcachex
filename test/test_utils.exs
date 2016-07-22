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
end

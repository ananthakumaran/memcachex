Code.require_file "./test_utils.exs", __DIR__
ExUnit.start(capture_log: true)

defmodule Test.Namespacer do
  def call(_key) do
    "app"
  end
end

defmodule BenchUtils do
  def random_string() do
    :crypto.strong_rand_bytes(10000) |> :base64.encode_to_string |> to_string
  end
end

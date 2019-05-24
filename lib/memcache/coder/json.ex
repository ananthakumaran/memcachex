if Code.ensure_loaded?(Poison) do
  defmodule Memcache.Coder.JSON do
    @moduledoc """
    Uses the `Poison` module to encode and decode value. To use this
    coder add `poison` as a dependency in `mix.exs`.
    """
    @behaviour Memcache.Coder

    def encode(value, options), do: Poison.encode!(value, options)
    def decode(value, options), do: Poison.decode!(value, options)
  end
end

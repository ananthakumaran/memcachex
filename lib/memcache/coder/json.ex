if Code.ensure_loaded?(Poison) do
  defmodule Memcache.Coder.JSON do
    @moduledoc """
    Uses the `Poison` module to encode and decode value. To use this
    coder add `poison` as a dependency in `mix.exs`.
    """
    use Memcache.Coder

    def encode(value, options), do: Poison.encode_to_iodata!(value, options)
    def encode_flags(_value, _options), do: [:serialised]
    def decode(value, options), do: Poison.decode!(value, options)
  end
end

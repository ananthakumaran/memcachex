defmodule Memcache.Coder.Erlang do
  @moduledoc """
  Uses `:erlang.term_to_binary/2` and `:erlang.binary_to_term/1` to
  encode and decode value.
  """
  use Memcache.Coder

  def encode(value, options), do: :erlang.term_to_binary(value, options)
  def decode(value, _options), do: :erlang.binary_to_term(value)
end

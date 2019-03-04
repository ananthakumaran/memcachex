defmodule Memcache.Coder.Raw do
  @moduledoc """
  Doesn't do any conversion. Stores the value as it is in the server.
  """
  use Memcache.Coder

  def encode(value, _options), do: value
  def decode(value, _options), do: value
end

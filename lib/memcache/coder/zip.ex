defmodule Memcache.Coder.ZIP do
  @moduledoc """
  Uses `:zlib.zip/1` and `:zlib.unzip/1` to compress and decompress
  value.
  """
  use Memcache.Coder

  def encode(value, _options), do: :zlib.zip(value)
  def decode(value, _options), do: :zlib.unzip(value)
end

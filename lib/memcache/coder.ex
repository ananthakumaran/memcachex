defmodule Memcache.Coder do
  @moduledoc """
  Defines the `Memcache.Coder` behaviour. A list would be passed to
  both `encode/2` and `decode/2` callbacks. This value can be
  specified by the user. Defaults to `[]` in case it is not specified.
  """

  @doc """
  Called before the value is sent to the server. It should return
  iodata.
  """
  @callback encode(any, options :: Keyword.t()) :: iodata

  @doc """
  Called after the value is loaded from the server. It can return any
  type.
  """
  @callback decode(iodata, options :: Keyword.t()) :: any
end

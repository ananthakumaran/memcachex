defmodule Memcache.Coder do
  @moduledoc """
  Defines the `Memcache.Coder` behaviour. A list would be passed to
  both `encode/2` and `decode/2` callbacks. This value can be
  specified by the user. Defaults to `[]` incase it is not specified.
  """

  @doc """
  Called before the value is sent to the server. It should return
  iodata.
  """
  @callback encode(any, options :: Keyword.t()) :: iodata

  @doc """
  Called before the value is sent to the server. It should return
  the flags to set by default for this coder as a list

  Valid flags:
  - :serialised
  - :compressed

  Example:
      iex> value = %{}
      iex> options = [flags: [:compressed]]
      iex> encode_flags(value, options)
      [:compressed, :serialised]

      iex> encode_flags(value)
      [:serialised]
  """
  @callback encode_flags(any, options :: Keyword.t()) :: list(atom)

  @doc """
  Called after the value is loaded from the server. It can return any
  type.
  """
  @callback decode(iodata, options :: Keyword.t()) :: any

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      def encode_flags(value, options) do
        flags = options[:flags]

        if !is_nil(flags) do
          flags
        else
          []
        end
      end

      defoverridable encode_flags: 2
    end
  end
end

defmodule Memcache.BinaryUtils do
  @moduledoc false

  @ops [
    GET: 0x00,
    SET: 0x01,
    ADD: 0x02,
    REPLACE: 0x03,
    DELETE: 0x04,
    INCREMENT: 0x05,
    DECREMENT: 0x06,
    QUIT: 0x07,
    FLUSH: 0x08,
    GETQ: 0x09,
    NOOP: 0x0A,
    VERSION: 0x0B,
    GETK: 0x0C,
    GETKQ: 0x0D,
    APPEND: 0x0E,
    PREPEND: 0x0F,
    STAT: 0x10,
    SETQ: 0x11,
    ADDQ: 0x12,
    REPLACEQ: 0x13,
    DELETEQ: 0x14,
    INCREMENTQ: 0x15,
    DECREMENTQ: 0x16,
    QUITQ: 0x17,
    FLUSHQ: 0x18,
    APPENDQ: 0x19,
    PREPENDQ: 0x1A,
    AUTH_LIST: 0x20,
    AUTH_START: 0x21,
    AUTH_STEP: 0x22
  ]

  # http://www.hjp.at/zettel/m/memcached_flags.rxml
  @flags [
    serialised: 0x1,
    compressed: 0x2
  ]

  defmacro opb(x) do
    quote do
      <<unquote(Keyword.fetch!(@ops, x))>>
    end
  end

  defmacro op(x) do
    quote do
      unquote(Keyword.fetch!(@ops, x))
    end
  end

  def flag_bit(x) do
    Keyword.fetch!(@flags, x)
  end

  def flags, do: @flags

  defmodule Header do
    @moduledoc false

    defstruct opcode: nil,
              key_length: nil,
              extra_length: nil,
              data_type: nil,
              status: nil,
              total_body_length: nil,
              opaque: nil,
              cas: nil
  end

  defmacro defparse_empty(name) do
    quote do
      def parse_body(%Header{status: 0x0000, opcode: op(unquote(name)), opaque: opaque}, :empty) do
        {opaque, {:ok}}
      end
    end
  end

  defmacro defparse_error(code, error) do
    quote do
      def parse_body(%Header{status: unquote(code), opaque: opaque}, _rest) do
        {opaque, {:error, unquote(error)}}
      end
    end
  end

  defmacro bcat(binaries) do
    {parts, _} = Code.eval_quoted(binaries, [], __CALLER__)

    quote do
      unquote(Enum.reduce(parts, <<>>, fn x, a -> a <> x end))
    end
  end

  defmacro request do
    quote do: <<0x80>>
  end

  defmacro reserved do
    quote do: <<0x0000::size(16)>>
  end

  defmacro datatype do
    quote do: <<0x00>>
  end

  defmacro opaque do
    quote do: <<0x00::size(32)>>
  end
end

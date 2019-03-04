# https://github.com/memcached/old-wiki/blob/master/MemcacheBinaryProtocol.wiki
defmodule Memcache.Protocol do
  @moduledoc false

  use Bitwise
  import Memcache.BinaryUtils
  alias Memcache.BinaryUtils.Header

  def to_binary(:QUIT, opaque) do
    [
      bcat([
        request(),
        opb(:QUIT),
        <<0x00::size(16)>>,
        <<0x00>>,
        datatype(),
        reserved(),
        <<0x00::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>
    ]
  end

  def to_binary(:QUITQ, opaque) do
    [
      bcat([
        request(),
        opb(:QUITQ),
        <<0x00::size(16)>>,
        <<0x00>>,
        datatype(),
        reserved(),
        <<0x00::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>
    ]
  end

  def to_binary(:NOOP, opaque) do
    [
      bcat([
        request(),
        opb(:NOOP),
        <<0x00::size(16)>>,
        <<0x00>>,
        datatype(),
        reserved(),
        <<0x00::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>
    ]
  end

  def to_binary(:VERSION, opaque) do
    [
      bcat([
        request(),
        opb(:VERSION),
        <<0x00::size(16)>>,
        <<0x00>>,
        datatype(),
        reserved(),
        <<0x00::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>
    ]
  end

  def to_binary(:STAT, opaque) do
    [
      bcat([
        request(),
        opb(:STAT),
        <<0x00::size(16)>>,
        <<0x00>>,
        datatype(),
        reserved(),
        <<0x00::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>
    ]
  end

  def to_binary(:AUTH_LIST, opaque) do
    [
      bcat([
        request(),
        opb(:AUTH_LIST),
        <<0x00::size(16)>>,
        <<0x00>>,
        datatype(),
        reserved(),
        <<0x00::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>
    ]
  end

  def to_binary(command, opaque) do
    to_binary(command, opaque, 0)
  end

  def to_binary(:STAT, opaque, key) do
    [
      bcat([request(), opb(:STAT)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      key
    ]
  end

  def to_binary(:GET, opaque, key) do
    [
      bcat([request(), opb(:GET)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      key
    ]
  end

  def to_binary(:GETQ, opaque, key) do
    [
      bcat([request(), opb(:GETQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      key
    ]
  end

  def to_binary(:GETK, opaque, key) do
    [
      bcat([request(), opb(:GETK)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      key
    ]
  end

  def to_binary(:GETKQ, opaque, key) do
    [
      bcat([request(), opb(:GETKQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      key
    ]
  end

  def to_binary(:FLUSH, opaque, expiry) do
    [
      bcat([
        request(),
        opb(:FLUSH),
        <<0x00::size(16)>>,
        <<0x04>>,
        datatype(),
        reserved(),
        <<0x04::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      <<expiry::size(32)>>
    ]
  end

  def to_binary(:FLUSHQ, opaque, expiry) do
    [
      bcat([
        request(),
        opb(:FLUSHQ),
        <<0x00::size(16)>>,
        <<0x04>>,
        datatype(),
        reserved(),
        <<0x04::size(32)>>
      ]),
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      <<expiry::size(32)>>
    ]
  end

  def to_binary(:AUTH_START, opaque, key) do
    [
      bcat([request(), opb(:AUTH_START)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      key
    ]
  end

  def to_binary(command, opaque, key) do
    to_binary(command, opaque, key, 0)
  end

  def to_binary(:AUTH_START, opaque, key, value) do
    [
      bcat([request(), opb(:AUTH_START)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key) + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<0x00::size(64)>>,
      key,
      value
    ]
  end

  def to_binary(:DELETE, opaque, key, cas) do
    [
      bcat([request(), opb(:DELETE)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      key
    ]
  end

  def to_binary(:DELETEQ, opaque, key, cas) do
    [
      bcat([request(), opb(:DELETEQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      key
    ]
  end

  def to_binary(command, opaque, key, value) do
    to_binary(command, opaque, key, value, 0)
  end

  def to_binary(:APPEND, opaque, key, value, cas) do
    [
      bcat([request(), opb(:APPEND)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key) + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      key,
      value
    ]
  end

  def to_binary(:APPENDQ, opaque, key, value, cas) do
    [
      bcat([request(), opb(:APPENDQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key) + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      key,
      value
    ]
  end

  def to_binary(:PREPEND, opaque, key, value, cas) do
    [
      bcat([request(), opb(:PREPEND)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key) + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      key,
      value
    ]
  end

  def to_binary(:PREPENDQ, opaque, key, value, cas) do
    [
      bcat([request(), opb(:PREPENDQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x00>>, datatype(), reserved()]),
      <<byte_size(key) + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      key,
      value
    ]
  end

  def to_binary(command, opaque, key, value, cas) do
    to_binary(command, opaque, key, value, cas, 0)
  end

  def to_binary(command, opaque, key, value, cas, flag) do
    to_binary(command, opaque, key, value, cas, flag, 0)
  end

  def to_binary(:INCREMENT, opaque, key, delta, initial, cas, expiry) do
    [
      bcat([request(), opb(:INCREMENT)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x14>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 20::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<delta::size(64)>>,
      <<initial::size(64)>>,
      <<expiry::size(32)>>,
      key
    ]
  end

  def to_binary(:INCREMENTQ, opaque, key, delta, initial, cas, expiry) do
    [
      bcat([request(), opb(:INCREMENTQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x14>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 20::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<delta::size(64)>>,
      <<initial::size(64)>>,
      <<expiry::size(32)>>,
      key
    ]
  end

  def to_binary(:DECREMENT, opaque, key, delta, initial, cas, expiry) do
    [
      bcat([request(), opb(:DECREMENT)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x14>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 20::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<delta::size(64)>>,
      <<initial::size(64)>>,
      <<expiry::size(32)>>,
      key
    ]
  end

  def to_binary(:DECREMENTQ, opaque, key, delta, initial, cas, expiry) do
    [
      bcat([request(), opb(:DECREMENTQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x14>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 20::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<delta::size(64)>>,
      <<initial::size(64)>>,
      <<expiry::size(32)>>,
      key
    ]
  end

  def to_binary(:SET, opaque, key, value, cas, expiry, flag) do
    if cas == [] do
      raise "can't have a list here. you need to fix something."
    end

    [
      bcat([request(), opb(:SET)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x08>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 8 + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<flag::size(32)>>,
      <<expiry::size(32)>>,
      key,
      value
    ]
  end

  def to_binary(:SETQ, opaque, key, value, cas, expiry, flag) do
    [
      bcat([request(), opb(:SETQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x08>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 8 + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<flag::size(32)>>,
      <<expiry::size(32)>>,
      key,
      value
    ]
  end

  def to_binary(:ADD, opaque, key, value, expiry, cas, flag) do
    [
      bcat([request(), opb(:ADD)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x08>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 8 + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<flag::size(32)>>,
      <<expiry::size(32)>>,
      key,
      value
    ]
  end

  def to_binary(:ADDQ, opaque, key, value, cas, expiry, flag) do
    [
      bcat([request(), opb(:ADDQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x08>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 8 + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<flag::size(32)>>,
      <<expiry::size(32)>>,
      key,
      value
    ]
  end

  def to_binary(:REPLACE, opaque, key, value, cas, expiry, flag) do
    [
      bcat([request(), opb(:REPLACE)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x08>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 8 + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<flag::size(32)>>,
      <<expiry::size(32)>>,
      key,
      value
    ]
  end

  def to_binary(:REPLACEQ, opaque, key, value, cas, expiry, flag) do
    [
      bcat([request(), opb(:REPLACEQ)]),
      <<byte_size(key)::size(16)>>,
      bcat([<<0x08>>, <<0x00>>, <<0x0000::size(16)>>]),
      <<byte_size(key) + 8 + IO.iodata_length(value)::size(32)>>,
      <<opaque::size(32)>>,
      <<cas::size(64)>>,
      <<flag::size(32)>>,
      <<expiry::size(32)>>,
      key,
      value
    ]
  end

  def parse_header(<<
        0x81::size(8),
        opcode::size(8),
        key_length::size(16),
        extra_length::size(8),
        data_type::size(8),
        status::size(16),
        total_body_length::size(32),
        opaque::size(32),
        cas::size(64)
      >>) do
    %Header{
      opcode: opcode,
      key_length: key_length,
      extra_length: extra_length,
      data_type: data_type,
      status: status,
      total_body_length: total_body_length,
      opaque: opaque,
      cas: cas
    }
  end

  def total_body_size(%Header{total_body_length: size}) do
    size
  end

  def parse_body(
        %Header{
          status: 0x0000,
          opcode: op(:GET) = op,
          extra_length: extra_length,
          total_body_length: total_body_length,
          opaque: opaque
        },
        rest
      ) do
    value_size = total_body_length - extra_length
    <<extra::binary-size(extra_length), value::binary-size(value_size)>> = rest

    flags = parse_flags(op, extra)

    {opaque, {:ok, value, flags}}
  end

  def parse_body(
        %Header{
          status: 0x0000,
          opcode: op(:GETQ) = op,
          extra_length: extra_length,
          total_body_length: total_body_length,
          opaque: opaque
        },
        rest
      ) do
    value_size = total_body_length - extra_length
    <<extra::binary-size(extra_length), value::binary-size(value_size)>> = rest

    flags = parse_flags(op, extra)

    {opaque, {:ok, value, flags}}
  end

  def parse_body(
        %Header{
          status: 0x0000,
          opcode: op(:GETK) = op,
          extra_length: extra_length,
          key_length: key_length,
          total_body_length: total_body_length,
          opaque: opaque
        },
        rest
      ) do
    value_size = total_body_length - extra_length - key_length

    <<extra::binary-size(extra_length), key::binary-size(key_length),
      value::binary-size(value_size)>> = rest

    flags = parse_flags(op, extra)

    {opaque, {:ok, key, value, flags}}
  end

  def parse_body(
        %Header{
          status: 0x0000,
          opcode: op(:GETKQ) = op,
          extra_length: extra_length,
          key_length: key_length,
          total_body_length: total_body_length,
          opaque: opaque
        },
        rest
      ) do
    value_size = total_body_length - extra_length - key_length

    <<extra::binary-size(extra_length), key::binary-size(key_length),
      value::binary-size(value_size)>> = rest

    flags = parse_flags(op, extra)

    {opaque, {:ok, key, value, flags}}
  end

  def parse_body(%Header{status: 0x0000, opcode: op(:VERSION), opaque: opaque}, rest) do
    {opaque, {:ok, rest}}
  end

  def parse_body(%Header{status: 0x0000, opcode: op(:AUTH_LIST), opaque: opaque}, rest) do
    {opaque, {:ok, rest}}
  end

  def parse_body(%Header{status: 0x0000, opcode: op(:INCREMENT), opaque: opaque}, rest) do
    <<value::size(64)>> = rest
    {opaque, {:ok, value}}
  end

  def parse_body(%Header{status: 0x0000, opcode: op(:INCREMENTQ), opaque: opaque}, rest) do
    <<value::size(64)>> = rest
    {opaque, {:ok, value}}
  end

  def parse_body(%Header{status: 0x0000, opcode: op(:DECREMENT), opaque: opaque}, rest) do
    <<value::size(64)>> = rest
    {opaque, {:ok, value}}
  end

  def parse_body(%Header{status: 0x0000, opcode: op(:DECREMENTQ), opaque: opaque}, rest) do
    <<value::size(64)>> = rest
    {opaque, {:ok, value}}
  end

  def parse_body(%Header{status: 0x0000, opcode: op(:AUTH_START), opaque: opaque}, _rest) do
    {opaque, {:ok}}
  end

  def parse_body(
        %Header{
          status: 0x0000,
          opcode: op(:STAT),
          key_length: 0,
          total_body_length: 0,
          opaque: opaque
        },
        _rest
      ) do
    {opaque, {:ok, :done}}
  end

  def parse_body(
        %Header{
          status: 0x0000,
          opcode: op(:STAT),
          key_length: key_length,
          total_body_length: total_body_length,
          opaque: opaque
        },
        rest
      ) do
    value_size = total_body_length - key_length
    <<key::binary-size(key_length), value::binary-size(value_size)>> = rest
    {opaque, {:ok, key, value}}
  end

  def parse_body(%Header{status: 0x0021, opaque: opaque}, body) do
    {opaque, {:error, :auth_step, body}}
  end

  @get_commands [op(:GET), op(:GETQ), op(:GETK), op(:GETKQ)]
  def parse_flags(command, <<extra::32>>) when command in @get_commands do
    Enum.reduce(flags(), [], fn {flag_name, flag_bits}, flags ->
      if (extra &&& flag_bits) != 0, do: [flag_name | flags], else: flags
    end)
  end

  def parse_flags(_command, _extra) do
    []
  end

  defparse_empty(:SET)
  defparse_empty(:ADD)
  defparse_empty(:REPLACE)
  defparse_empty(:DELETE)
  defparse_empty(:QUIT)
  defparse_empty(:FLUSH)
  defparse_empty(:NOOP)
  defparse_empty(:APPEND)
  defparse_empty(:PREPEND)

  defparse_error(0x0001, "Key not found")
  defparse_error(0x0002, "Key exists")
  defparse_error(0x0003, "Value too large")
  defparse_error(0x0004, "Invalid arguments")
  defparse_error(0x0005, "Item not stored")
  defparse_error(0x0006, "Incr/Decr on non-numeric value")
  defparse_error(0x0008, "Authentication Error")
  defparse_error(0x0009, "Authentication Continue")
  defparse_error(0x0020, "Authentication required / Not Successful")
  defparse_error(0x0081, "Unknown command")
  defparse_error(0x0082, "Out of memory")

  def quiet_response(:GETQ), do: {:error, "Key not found"}
  def quiet_response(:GETKQ), do: {:error, "Key not found"}
  def quiet_response(:SETQ), do: {:ok}
  def quiet_response(:ADDQ), do: {:ok}
  def quiet_response(:DELETEQ), do: {:ok}
  def quiet_response(:REPLACEQ), do: {:ok}
  def quiet_response(:INCREMENTQ), do: {:ok}
  def quiet_response(:DECREMENTQ), do: {:ok}
  def quiet_response(:APPENDQ), do: {:ok}
  def quiet_response(:PREPENDQ), do: {:ok}
  def quiet_response(:FLUSHQ), do: {:ok}
  def quiet_response(:QUITQ), do: {:ok}
end

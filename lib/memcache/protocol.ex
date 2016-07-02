# https://github.com/memcached/old-wiki/blob/master/MemcacheBinaryProtocol.wiki

defmodule Memcache.Protocol do
  import Memcache.BinaryUtils
  alias Memcache.BinaryUtils.Header

  def to_binary(:QUIT) do
    bcat([ request, opb(:QUIT), << 0x00 :: size(16) >>,
          << 0x00 >>, datatype, reserved,
          << 0x00 :: size(32) >>, opaque,
          << 0x00 :: size(64) >> ])
  end

  def to_binary(:NOOP) do
    bcat([ request, opb(:NOOP), << 0x00 :: size(16) >>,
          << 0x00 >>, datatype, reserved,
          << 0x00 :: size(32) >>, opaque,
          << 0x00 :: size(64) >> ])
  end

  def to_binary(:VERSION) do
    bcat([ request, opb(:VERSION), << 0x00 :: size(16) >>,
          << 0x00 >>, datatype, reserved,
          << 0x00 :: size(32) >>, opaque,
          << 0x00 :: size(64) >> ])
  end

  def to_binary(:STAT) do
    bcat([ request, opb(:STAT), << 0x00 :: size(16) >>,
          << 0x00 >>, datatype, reserved,
          << 0x00 :: size(32) >>, opaque,
          << 0x00 :: size(64) >> ])
  end

  def to_binary(command) do
    to_binary(command, 0)
  end

  def to_binary(:NOOP, opaque) do
    bcat([ request, opb(:NOOP), << 0x00 :: size(16) >>,
          << 0x00 >>, datatype, reserved,
          << 0x00 :: size(32) >>]) <>
      << opaque :: size(32) >> <>
      << 0x00 :: size(64) >>
  end

  def to_binary(:STAT, key) do
    bcat([ request, opb(:STAT)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) :: size(32) >> <>
    bcat([ opaque, << 0x00 :: size(64) >>]) <>
    key
  end

  def to_binary(:GET, key) do
    bcat([ request, opb(:GET)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) :: size(32) >> <>
    bcat([ opaque, << 0x00 :: size(64) >>]) <>
    key
  end

  def to_binary(:GETK, key) do
    bcat([ request, opb(:GETK)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) :: size(32) >> <>
    bcat([ opaque, << 0x00 :: size(64) >>]) <>
    key
  end

  def to_binary(:DELETE, key) do
    bcat([ request, opb(:DELETE)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) :: size(32) >> <>
    bcat([ opaque, << 0x00 :: size(64) >>]) <>
    key
  end

  def to_binary(:FLUSH, 0) do
    bcat([ request, opb(:FLUSH), << 0x00 :: size(16) >>,
          << 0x00 >>, datatype, reserved,
          << 0x00 :: size(32) >>, opaque,
          << 0x00 :: size(64) >>])
  end

  def to_binary(:FLUSH, expiry) do
    bcat([ request, opb(:FLUSH), << 0x00 :: size(16) >>,
          << 0x04 >>, datatype, reserved,
          << 0x04 :: size(32) >>, opaque,
          << 0x00 :: size(64) >> ]) <>
    << expiry :: size(32) >>
  end

  def to_binary(command, key) do
    to_binary(command, key, 0)
  end

  def to_binary(:GETQ, id, key) do
    bcat([ request, opb(:GETQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) :: size(32) >> <>
    << id :: size(32) >> <>
    << 0x00 :: size(64) >> <>
    key
  end

  def to_binary(:GETKQ, id, key) do
    bcat([ request, opb(:GETKQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) :: size(32) >> <>
    << id :: size(32) >> <>
    << 0x00 :: size(64) >> <>
    key
  end

  def to_binary(:DELETEQ, id, key) do
    bcat([ request, opb(:DELETEQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) :: size(32) >> <>
    << id :: size(32) >> <>
    << 0x00 :: size(64) >> <>
    key
  end

  def to_binary(:APPEND, key, value) do
    bcat([ request, opb(:APPEND)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) + byte_size(value) :: size(32) >> <>
    bcat([ opaque, << 0x00 :: size(64) >>]) <>
    key <>
    value
  end

  def to_binary(:PREPEND, key, value) do
    bcat([ request, opb(:PREPEND)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) + byte_size(value) :: size(32) >> <>
    bcat([ opaque, << 0x00 :: size(64) >>]) <>
    key <>
    value
  end

  def to_binary(command, key, value) do
    to_binary(command, key, value, 0, 0, 0)
  end

  def to_binary(:APPENDQ, id, key, value) do
    bcat([ request, opb(:APPENDQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) + byte_size(value) :: size(32) >> <>
    << id :: size(32) >> <>
    << 0x00 :: size(64) >> <>
    key <>
    value
  end

  def to_binary(:PREPENDQ, id, key, value) do
    bcat([ request, opb(:PREPENDQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x00 >>, datatype, reserved]) <>
    << byte_size(key) + byte_size(value) :: size(32) >> <>
    << id :: size(32) >> <>
    << 0x00 :: size(64) >> <>
    key <>
    value
  end

  def to_binary(command, key, value, cas) do
    to_binary(command, key, value, cas, 0, 0)
  end

  def to_binary(command, key, value, cas, flag) do
    to_binary(command, key, value, cas, flag, 0)
  end

  def to_binary(:INCREMENT, key, delta, initial, cas, expiry) do
    bcat([ request, opb(:INCREMENT)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x14 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 20 :: size(32) >> <>
    opaque <>
    << cas :: size(64) >> <>
    << delta :: size(64) >> <>
    << initial :: size(64) >> <>
    << expiry :: size(32) >> <>
    key
  end

  def to_binary(:DECREMENT, key, delta, initial, cas, expiry) do
    bcat([ request, opb(:DECREMENT)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x14 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 20 :: size(32) >> <>
    opaque <>
    << cas :: size(64) >> <>
    << delta :: size(64) >> <>
    << initial :: size(64) >> <>
    << expiry :: size(32) >> <>
    key
  end

  def to_binary(:SET, key, value, cas, flag, expiry) do
    bcat([ request, opb(:SET)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    opaque <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(:ADD, key, value, cas, flag, expiry) do
    bcat([ request, opb(:ADD)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    opaque <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(:REPLACE, key, value, cas, flag, expiry) do
    bcat([ request, opb(:REPLACE)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    opaque <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(command, id, key, value, cas, flag) do
    to_binary(command, id, key, value, cas, flag, 0)
  end

  def to_binary(:SETQ, id, key, value, cas, flag, expiry) do
    bcat([ request, opb(:SETQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    << id :: size(32) >> <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(:ADDQ, id, key, value, cas, flag, expiry) do
    bcat([ request, opb(:ADDQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    << id :: size(32) >> <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(:REPLACEQ, id, key, value, cas, flag, expiry) do
    bcat([ request, opb(:REPLACEQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x08 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    << id :: size(32) >> <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  def to_binary(:INCREMENTQ, id, key, delta, initial, cas, expiry) do
    bcat([ request, opb(:INCREMENTQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x14 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 20 :: size(32) >> <>
    << id :: size(32) >> <>
    << cas :: size(64) >> <>
    << delta :: size(64) >> <>
    << initial :: size(64) >> <>
    << expiry :: size(32) >> <>
    key
  end

  def to_binary(:DECREMENTQ, id, key, delta, initial, cas, expiry) do
    bcat([ request, opb(:DECREMENTQ)]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<< 0x14 >>, << 0x00 >>, << 0x0000 :: size(16) >>]) <>
    << byte_size(key) + 20 :: size(32) >> <>
    << id :: size(32) >> <>
    << cas :: size(64) >> <>
    << delta :: size(64) >> <>
    << initial :: size(64) >> <>
    << expiry :: size(32) >> <>
    key
  end


  def parse_header(<<
                   0x81 :: size(8),
                   opcode :: size(8),
                   key_length :: size(16),
                   extra_length :: size(8),
                   data_type :: size(8),
                   status :: size(16),
                   total_body_length :: size(32),
                   opaque :: size(32),
                   cas :: size(64)
                   >>) do
    %Header{ opcode: opcode, key_length: key_length, extra_length: extra_length, data_type: data_type, status: status, total_body_length: total_body_length, opaque: opaque, cas: cas }
  end

  def total_body_size(%Header{total_body_length: size}) do
    size
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:GET), extra_length: extra_length, total_body_length: total_body_length }, rest) do
    value_size = (total_body_length - extra_length)
    << _extra :: binary-size(extra_length),  value :: binary-size(value_size) >> = rest
    { :ok, value }
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:GETQ), extra_length: extra_length, total_body_length: total_body_length, opaque: opaque }, rest) do
    value_size = (total_body_length - extra_length)
    << _extra :: binary-size(extra_length),  value :: binary-size(value_size) >> = rest
    { opaque, { :ok, value } }
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:GETK), extra_length: extra_length, key_length: key_length, total_body_length: total_body_length }, rest) do
    value_size = (total_body_length - extra_length - key_length)
    << _extra :: binary-size(extra_length), key :: binary-size(key_length), value :: binary-size(value_size) >> = rest
    { :ok, key, value }
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:GETKQ), extra_length: extra_length, key_length: key_length, total_body_length: total_body_length, opaque: opaque }, rest) do
    value_size = (total_body_length - extra_length - key_length)
    << _extra :: binary-size(extra_length), key :: binary-size(key_length), value :: binary-size(value_size) >> = rest
    { opaque, { :ok, key, value }}
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:VERSION) }, rest) do
    { :ok, rest }
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:INCREMENT) }, rest) do
    << value :: size(64) >> = rest
    { :ok, value }
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:INCREMENTQ), opaque: opaque }, rest) do
    << value :: size(64) >> = rest
    { opaque, { :ok, value }}
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:DECREMENT) }, rest) do
    << value :: size(64) >> = rest
    { :ok, value }
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:DECREMENTQ), opaque: opaque }, rest) do
    << value :: size(64) >> = rest
    { opaque, { :ok, value }}
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:STAT), key_length: 0, total_body_length: 0 }, _rest) do
    { :ok, :done }
  end

  def parse_body(%Header{ status: 0x0000, opcode: op(:STAT), key_length: key_length, total_body_length: total_body_length }, rest) do
    value_size = (total_body_length - key_length)
    << key :: binary-size(key_length),  value :: binary-size(value_size) >> = rest
    { :ok, key, value }
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
  defparse_error(0x0081, "Unknown command")
  defparse_error(0x0082, "Out of memory")

  def quiet_response(:GETQ), do: { :ok, "Key not found" }
  def quiet_response(:GETKQ), do: { :ok, "Key not found" }
  def quiet_response(:SETQ), do: { :ok }
  def quiet_response(:ADDQ), do: { :ok }
  def quiet_response(:DELETEQ), do: { :ok }
  def quiet_response(:REPLACEQ), do: { :ok }
  def quiet_response(:INCREMENTQ), do: { :ok }
  def quiet_response(:DECREMENTQ), do: { :ok }
  def quiet_response(:APPENDQ), do: { :ok }
  def quiet_response(:PREPENDQ), do: { :ok }

end

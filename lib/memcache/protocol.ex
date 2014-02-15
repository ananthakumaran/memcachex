# https://code.google.com/p/memcached/wiki/MemcacheBinaryProtocol

defmodule Memcache.Protocol do
  import Memcache.BinaryUtils

  def to_binary(:GET, key) do
    bcat([<<0x80>>, <<0x00>>]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<<0x00>>, <<0x00>>, <<0x0000 :: size(16) >>]) <>
    << byte_size(key) :: size(32) >> <>
    bcat([<<0x00 :: size(32)>>, <<0x00 :: size(64)>>]) <>
    key
  end

  def to_binary(:SET, key, value, cas // 0, flag // 1, expiry // 0) do
    bcat([<<0x80>>, <<0x01>>]) <>
    << byte_size(key) :: size(16) >> <>
    bcat([<<0x08>>, <<0x00>>, <<0x0000 :: size(16) >>]) <>
    << byte_size(key) + 8 + byte_size(value) :: size(32) >> <>
    << 0x00 :: size(32) >> <>
    << cas :: size(64) >> <>
    << flag :: size(32) >> <>
    << expiry :: size(32) >> <>
    key <>
    value
  end

  defrecordp :header, [ :opcode, :key_length, :extra_length, :data_type, :status, :total_body_length, :opaque, :cas ]

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
    header(opcode: opcode, key_length: key_length, extra_length: extra_length, data_type: data_type, status: status, total_body_length: total_body_length, opaque: opaque, cas: cas)
  end

  def total_body_size(header(total_body_length: size)) do
    size
  end

  def wait_for_response?(command) do
    true
  end

  def parse_body(header(status: 0x0000, opcode: 0x00, extra_length: extra_length, total_body_length: total_body_length) = h, rest) do
    value_size = (total_body_length - extra_length)
    << extra :: bsize(extra_length),  value :: bsize(value_size) >> = rest
    { :ok, value }
  end

  def parse_body(header(status: 0x0000, opcode: 0x01) = h, :empty) do
    { :ok }
  end

  def parse_body(header(status: 0x0001), rest) do
    { :error, "Key not found" }
  end

  def parse_body(header(status: 0x0002), rest) do
    { :error, "Key exists" }
  end

  def parse_body(header(status: 0x0003), rest) do
    { :error, "Value too large" }
  end

  def parse_body(header(status: 0x0004), rest) do
    { :error, "Invalid arguments" }
  end

  def parse_body(header(status: 0x0005), rest) do
    { :error, "Item not stored" }
  end

  def parse_body(header(status: 0x0006), rest) do
    { :error, "Incr/Decr on non-numeric value" }
  end

  def parse_body(header(status: 0x0081), rest) do
    { :error, "Unknown command" }
  end

  def parse_body(header(status: 0x0082), rest) do
    { :error, "Out of memory" }
  end
end

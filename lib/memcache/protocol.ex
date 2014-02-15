defmodule Memcache.Protocol do
  def to_binary(:get, [key]) do
    <<0x80>> <> <<0x00>> <> << byte_size(key) :: size(16) >> <> <<0x00>> <> <<0x00>> <> <<0x0000 :: size(16) >> <> << byte_size(key) :: size(32) >> <> <<0x00 :: size(32)>> <> <<0x00 :: size(64)>> <> key
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

  def parse_body(_header, rest) do
    rest
  end
end

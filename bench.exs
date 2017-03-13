alias Memcache.Connection

defmodule Utils do
  def random_string(size \\ 10000) do
    :crypto.strong_rand_bytes(size) |> :base64.encode_to_string |> to_string
  end
end

{ :ok, mcd} = :mcd.start_link(['localhost', 11211])
{ :ok, pid } = Connection.start_link([ hostname: "localhost" ])
{ :ok } = Connection.execute(pid, :SET, ["hello", "world"])
large_blob = Utils.random_string()
{ :ok } = Connection.execute(pid, :SET, ["hello_large", large_blob])
getq_query = Enum.map(Range.new(1, 100), fn (_) -> {:GETQ, ["hello"]} end)
setq_query = Enum.map(Range.new(1, 100), fn (_) -> {:SETQ, ["hello", Utils.random_string()]} end)

{:ok, _} = :mcd.set(mcd, "hello", "world")
{:ok, _} = :mcd.set(mcd, "hello_large", large_blob)

Benchee.run(%{
  "sleep" => fn -> Process.sleep(100) end,
  "memcachex.GET" => fn -> { :ok, "world" } = Connection.execute(pid, :GET, ["hello"]) end,
  "mcd.GET" => fn -> { :ok, "world" } = :mcd.get(mcd, "hello") end,
  "memcachex.SET" => fn -> { :ok } = Connection.execute(pid, :SET, ["hello", "world"]) end,
  "mcd.SET" => fn -> { :ok, "world" } = :mcd.set(mcd, "hello", "world") end,
  "memcachex.SET LARGE" => fn -> { :ok } = Connection.execute(pid, :SET, ["hello_large", large_blob]) end,
  "mcd.SET LARGE" => fn -> { :ok, _ } = :mcd.set(mcd, "hello_large", large_blob) end,
  "memcachex.GET LARGE" => fn -> { :ok, _ } = Connection.execute(pid, :GET, ["hello_large"]) end,
  "mcd.GET LARGE" => fn -> { :ok, _ } = :mcd.get(mcd, "hello_large") end,
  "memcachex.GETQ" => fn -> Connection.execute_quiet(pid, getq_query) end,
  "memcachex.SETQ LARGE" => fn -> Connection.execute_quiet(pid, setq_query) end
}, parallel: 1)

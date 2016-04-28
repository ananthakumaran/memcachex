alias Memcache.Connection
defmodule MemcacheBench do
  use Benchfella

  before_each_bench _ do
    { :ok, pid } = Connection.start_link([ hostname: "localhost" ])
    { :ok } = Connection.execute(pid, :SET, ["hello", "world"])
    { :ok, pid }
  end

  bench "GET" do
    pid = bench_context
    { :ok, "world" } = Connection.execute(pid, :GET, ["hello"])
  end

  bench "SET" do
    pid = bench_context
    { :ok } = Connection.execute(pid, :SET, ["hello", "world"])
  end

  @query Enum.map(Range.new(1, 100), fn (_) -> {:GETQ, ["hello"]} end)
  bench "GETQ" do
    pid = bench_context
    Connection.execute_quiet(pid, @query)
  end
end

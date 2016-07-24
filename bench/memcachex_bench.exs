Code.require_file "./bench_utils.exs", __DIR__
alias Memcache.Connection
defmodule MemcachexBench do
  use Benchfella
  import BenchUtils

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

  bench "SET LARGE", [large_blob: random_string()] do
    pid = bench_context
    { :ok } = Connection.execute(pid, :SET, ["hello", large_blob])
    { :ok }
  end

  bench "GET LARGE" do
    pid = bench_context
    { :ok, _ } = Connection.execute(pid, :GET, ["hello"])
  end


  @query Enum.map(Range.new(1, 100), fn (_) -> {:GETQ, ["hello"]} end)
  bench "GETQ" do
    pid = bench_context
    Connection.execute_quiet(pid, @query)
  end

  bench "SETQ LARGE", [query: Enum.map(Range.new(1, 100), fn (_) -> {:SETQ, ["hello", random_string()]} end)]do
    pid = bench_context
    Connection.execute_quiet(pid, query)
    {:ok}
  end
end

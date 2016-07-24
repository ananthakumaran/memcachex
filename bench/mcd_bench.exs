Code.require_file "./bench_utils.exs", __DIR__
defmodule McdBench do
  use Benchfella
  import BenchUtils

  before_each_bench _ do
    { :ok, pid} = :mcd.start_link(['localhost', 11211])
    :timer.sleep(100)
    { :ok, "world" } = :mcd.set(pid, "hello", "world")
    { :ok, pid }
  end

  bench "GET" do
    pid = bench_context
    { :ok, "world" } = :mcd.get(pid, "hello")
  end

  bench "SET" do
    pid = bench_context
    { :ok, "world" } = :mcd.set(pid, "hello", "world")
  end

  bench "SET LARGE", [large_blob: random_string()] do
    pid = bench_context
    { :ok, _ } = :mcd.set(pid, "hello", large_blob)
    { :ok }
  end

  bench "GET LARGE" do
    pid = bench_context
    { :ok, _ } = :mcd.get(pid, "hello")
  end
end

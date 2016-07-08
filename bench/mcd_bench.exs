defmodule McdBench do
  use Benchfella

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
end

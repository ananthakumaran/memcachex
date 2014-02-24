require Benchmark
alias Memcache.Connection

{ :ok, pid } = Connection.start_link([ hostname: "localhost" ])
{ :ok } = Connection.execute(pid, :SET, ["hello", "world"])

result = Benchmark.run_for(1000_000) do
  { :ok, "world" } = Connection.execute(pid, :GET, ["hello"])
end
IO.puts "GET \n#{inspect result}"

result = Benchmark.run_for(1000_000) do
    { :ok } = Connection.execute(pid, :SET, ["hello", "world"])
end
IO.puts "SET \n#{inspect result}"

query = Enum.map(Range.new(1, 100), fn (_) -> {:GETQ, ["hello"]} end)

result = Benchmark.run_for(1000_000) do
  Connection.execute_quiet(pid, query)
end
IO.puts "GETQ with 100 commands \n#{inspect result}"

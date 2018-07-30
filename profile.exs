import ExProf.Macro
alias Memcache.Connection

{:ok, pid} = Connection.start_link(hostname: "localhost")
{:ok} = Connection.execute(pid, :SET, ["hello", "world"])

profile do
  Enum.each(Range.new(0, 10000), fn _ ->
    {:ok, "world"} = Connection.execute(pid, :GET, ["hello"])
  end)
end

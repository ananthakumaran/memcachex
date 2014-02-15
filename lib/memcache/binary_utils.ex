defmodule Memcache.BinaryUtils do
  defmacro bcat(binaries) do
    { parts, _ } = Code.eval_quoted(binaries)
    quote do
      unquote(Enum.reduce(parts, <<>>, fn (x, a) -> a <> x end))
    end
  end

  defmacro bsize(bytesize) do
    quote do
      [ size(unquote(bytesize)), binary ]
    end
  end
end

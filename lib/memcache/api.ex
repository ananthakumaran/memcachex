defmodule Memcache.Api do
  @moduledoc """
  """

  defmacro __using__(_) do
    quote do
      def get(server, key, opts \\ []) do
        GenServer.call(server, {:execute, :get, [key, opts]})
      end
    end
  end
end

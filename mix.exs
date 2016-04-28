defmodule Memcache.Mixfile do
  use Mix.Project

  def project do
    [ app: :memcache,
      version: "0.0.1",
      elixir: ">= 1.0.0",
      deps: deps(Mix.env) ]
  end

  def application do
    []
  end

  defp deps(:dev) do
    [{:benchfella, "~> 0.3.0"}] ++ deps()
  end

  defp deps(_), do: deps()

  defp deps do
    []
  end
end

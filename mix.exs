defmodule Memcache.Mixfile do
  use Mix.Project

  def project do
    [ app: :memcache,
      version: "0.0.1",
      elixir: "~> 0.12.4",
      deps: deps(Mix.env) ]
  end

  def application do
    []
  end

  defp deps(:dev) do
    [ { :benchmark, "~> 0.0.1", github: "ananthakumaran/elixir-benchmark" } ] ++ deps()
  end

  defp deps(_), do: deps()

  defp deps do
    []
  end
end

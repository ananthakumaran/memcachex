defmodule Memcache.Mixfile do
  use Mix.Project

  def project do
    [ app: :memcache,
      version: "0.0.1",
      elixir: "~> 0.11.2",
      deps: deps ]
  end

  def application do
    []
  end

  defp deps do
    []
  end
end

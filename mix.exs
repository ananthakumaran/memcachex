defmodule Memcache.Mixfile do
  @moduledoc false
  use Mix.Project

  @version "0.4.5"

  def project do
    [
      app: :memcachex,
      version: @version,
      elixir: ">= 1.3.0",
      description: "Memcached client",
      package: package(),
      docs: docs(),
      dialyzer: [
        plt_add_deps: :transitive,
        ignore_warnings: ".dialyzer_ignore",
        flags: [:unmatched_returns, :race_conditions, :error_handling, :underspecs]
      ],
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :connection], mod: {Memcache.Application, []}]
  end

  def deps() do
    [
      {:connection, "~> 1.0.3"},
      {:poison, "~> 2.1 or ~> 3.0 or ~> 4.0", optional: true},
      {:ex_doc, "~> 0.20.0", only: :dev},
      {:exprof, "~> 0.2.0", only: :dev},
      {:mcd, github: "EchoTeam/mcd", only: :dev},
      {:benchee, "~> 0.6", only: :dev},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:toxiproxy, "~> 0.3", only: :test},
      {:lager, "3.2.0",
       only: :dev, git: "git://github.com/basho/lager.git", tag: "3.2.0", override: true}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/ananthakumaran/memcachex"},
      maintainers: ["ananthakumaran@gmail.com"]
    }
  end

  defp docs do
    [
      source_url: "https://github.com/ananthakumaran/memcachex",
      source_ref: "v#{@version}",
      main: Memcache,
      extras: ["README.md"]
    ]
  end
end

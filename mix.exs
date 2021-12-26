defmodule Memcache.Mixfile do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/ananthakumaran/memcachex"
  @version "0.5.2"

  def project do
    [
      app: :memcachex,
      version: @version,
      elixir: "~> 1.6",
      package: package(),
      deps: deps(),
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Memcache.Application, []}
    ]
  end

  def deps() do
    [
      {:connection, "~> 1.0.3"},
      {:telemetry, "~> 0.4.0 or ~> 1.0"},
      {:poison, "~> 2.1 or ~> 3.0 or ~> 4.0", optional: true},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:exprof, "~> 0.2.0", only: :dev},
      {:benchee, "~> 0.6", only: :dev},
      {:toxiproxy, "~> 0.3", only: :test}
    ]
  end

  defp package do
    [
      description: "Memcached client for Elixir",
      licenses: ["MIT"],
      maintainers: ["ananthakumaran@gmail.com"],
      links: %{
        "Changelog" => "https://hexdocs.pm/memcachex/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        {:"LICENSE.md", [title: "License"]},
        "README.md"
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :transitive,
      ignore_warnings: ".dialyzer_ignore",
      flags: [:unmatched_returns, :race_conditions, :error_handling, :underspecs]
    ]
  end
end

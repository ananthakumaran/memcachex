defmodule Memcache.Mixfile do
  use Mix.Project

  @version "0.2.1"

  def project do
    [app: :memcachex,
     version: @version,
     elixir: ">= 1.1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "Memcached client",
     package: package(),
     docs: docs(),
     dialyzer: [plt_add_deps: :transitive],
     deps: deps(Mix.env)]
  end

  def application do
    [applications: [:logger, :connection],
     mod: {Memcachex, []}]
  end

  def deps(:dev) do
    [{:ex_doc, "~> 0.12", only: :dev},
     {:benchfella, "~> 0.3.0", only: :dev},
     {:exprof, "~> 0.2.0", only: :dev},
     {:mcd, github: "EchoTeam/mcd", only: :dev},
     {:mix_test_watch, "~> 0.2", only: :dev}] ++ deps()
  end
  def deps(_), do: deps()
  def deps() do
    [{:connection, "~> 1.0.3"},
     {:poison, "~> 1.5 or ~> 2.0", optional: true},
     {:poolboy, "~> 1.5"}]
  end

  defp package do
    %{licenses: ["MIT"],
      links: %{"Github" => "https://github.com/ananthakumaran/memcachex"},
      maintainers: ["ananthakumaran@gmail.com"]}
  end

  defp docs do
    [source_url: "https://github.com/ananthakumaran/memcachex",
     source_ref: "v#{@version}",
     main: Memcache,
     extras: ["README.md"]]
  end
end

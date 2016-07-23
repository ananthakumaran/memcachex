defmodule Memcache.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [app: :memcachex,
     version: @version,
     elixir: ">= 1.1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "Memcached client",
     package: package(),
     docs: docs(),
     deps: deps(Mix.env)]
  end

  def application do
    [applications: [:logger, :connection]]
  end

  def deps(:dev) do
    [{:ex_doc, "~> 0.12", only: :dev},
     {:benchfella, "~> 0.3.0", only: :dev},
     {:exprof, "~> 0.2.0", only: :dev},
     {:mcd, github: "EchoTeam/mcd", only: :dev},
     {:mix_test_watch, "~> 0.2", only: :dev}] ++ deps()
  end
  def deps(_), do: deps()
  def deps(), do: [{:connection, "~> 1.0.3"}]

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

defmodule Inter.MixProject do
  use Mix.Project

  def project do
    [
      app: :inter,
      version: "0.7.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      name: "Inter",
      description: "Banco Inter SDK (unofficial)",
      source_url: "https://github.com/marmita-fit/inter-sdk",
      package: package(),
      deps: deps()
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{
        "Documentation" => "https://developers.inter.co/",
        "GitHub" => "https://github.com/marmita-fit/inter-sdk"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Inter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, ">= 3.0.0 and <= 7.0.0"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.1"},
      {:nestru, "~> 1.0"},
      {:eqrcode, "~> 0.2"},
      {:decimal, "~> 2.0"},
      {:telemetry, "~> 1.2"},
      {:calendar, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

defmodule Mockable.MixProject do
  use Mix.Project

  @version "0.2.1"
  @description "Implementation delegation without boilerplate"
  @source_url "https://github.com/grantwest/mockable"

  def project do
    [
      app: :mockable,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: @description,
      aliases: aliases(),
      preferred_cli_env: [
        "test.watch": :test
      ],
      name: "Mockable",
      docs: docs(),
      test_paths: ["test/#{Mix.env()}"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:prod_test), do: ["lib", "test/support/client.ex"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:mox, "~> 1.2", only: :test, runtime: false}
    ]
  end

  defp aliases do
    []
  end

  defp package do
    %{
      licenses: ["0BSD"],
      maintainers: ["Grant West"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/mockable/changelog.html"
      }
    }
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme"
    ]
  end
end

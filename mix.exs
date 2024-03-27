defmodule AlertsConcierge.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      test_coverage: [tool: LcovEx],
      preferred_cli_env: [vcr: :test],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_add_apps: [:ex_unit]
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [
      {:credo, "~> 1.6.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test]},
      {:lcov_ex, "~> 0.2", only: [:dev, :test]},
      {:sobelow, "~> 0.11.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "ecto.migrate": ["ecto.migrate", "ecto.dump"],
      "ecto.setup": ["ecto.create", "ecto.load"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.rollback": ["ecto.rollback", "ecto.dump"],
      sobelow: [
        "sobelow --root apps/concierge_site --exit --skip --ignore Config.CSP,Config.HTTPS"
      ],
      test: ["ecto.create --quiet", "ecto.load --quiet --skip-if-loaded", "test"]
    ]
  end

  defp releases do
    [
      alerts_concierge: [
        applications: [alert_processor: :permanent, concierge_site: :permanent],
        include_executables_for: [:unix],
        version: "0.1.0"
      ]
    ]
  end
end

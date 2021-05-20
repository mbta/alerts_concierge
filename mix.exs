defmodule AlertsConcierge.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [vcr: :test, coveralls: :test],
      # required to ignore incorrect typespec for ExAws.SNS.verify_message
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs", plt_ignore_apps: [:ex_aws_sns]]
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
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:distillery, "~> 1.5", runtime: false},
      {:excoveralls, "~> 0.5", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "ecto.migrate": ["ecto.migrate", "ecto.dump"],
      "ecto.setup": ["ecto.create", "ecto.load"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.rollback": ["ecto.rollback", "ecto.dump"],
      test: ["ecto.create --quiet", "ecto.load --quiet", "test"]
    ]
  end
end

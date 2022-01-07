defmodule AlertProcessor.Mixfile do
  use Mix.Project

  def project do
    [
      app: :alert_processor,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # https://github.com/dariodf/lcov_ex/issues/2
      test_coverage: [tool: LcovEx]
    ]
  end

  # Configuration for the OTP application.
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {AlertProcessor, []}, extra_applications: [:logger, :runtime_tools]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 1.0"},
      {:bypass, "~> 0.9.0", only: :test},
      {:calendar, "~> 1.0.0"},
      {:comeonin, "~> 3.0"},
      {:con_cache, "~> 0.12.1"},
      {:cowboy, "~> 1.0"},
      {:ecto, "~> 2.2.0"},
      {:exactor, "~> 2.2.0"},
      {:ex_aws, "~> 2.1.0"},
      {:ex_aws_sns, "~> 2.2.0"},
      {:ex_machina, "~> 2.2.0", only: :test},
      {:exvcr, "~> 0.10.1", runtime: false},
      {:fast_local_datetime, "~> 1.0.0"},
      {:gettext, "~> 0.11"},
      {:hackney, "~> 1.17.0"},
      {:httpoison, "~> 1.1.1"},
      {:paper_trail, "~> 0.7.5"},
      {:poison, "~> 2.0"},
      {:poolboy, ">= 0.0.0"},
      {:postgrex, ">= 0.0.0"},
      {:scrivener_ecto, "~> 1.0"},
      {:sentry, "~> 7.0"},
      {:sweet_xml, "~> 0.6"},
      {:eflame, "~> 1.0", only: [:dev]},
      {:tzdata, "~> 1.1.0"},
      {:uuid, "~> 1.1.8"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  # defp aliases do
  #   ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
  #    "ecto.reset": ["ecto.drop", "ecto.setup"],
  #    "test": ["ecto.create --quiet", "ecto.migrate", "coveralls.json"]]
  # end
end

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
      compilers: Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # https://github.com/dariodf/lcov_ex/issues/2
      test_coverage: [tool: LcovEx],
      # Ignore warnings due to the circular dependency between AlertProcessor and ConciergeSite
      xref: [
        exclude: [
          ConciergeSite.Dissemination.Mailer,
          ConciergeSite.Dissemination.NotificationEmail
        ]
      ]
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
      {:bcrypt_elixir, "~> 3.0"},
      {:calendar, "~> 1.0.0"},
      {:con_cache, "~> 1.0.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_aws, "~> 2.2.0"},
      {:ex_aws_sns, "~> 2.3.1"},
      {:fast_local_datetime, "~> 1.0.0"},
      {:gettext, "~> 0.11"},
      {:httpoison, "~> 1.8.0"},
      {:paper_trail, "0.8.3"},
      {:poison, "~> 2.0"},
      {:poolboy, "~> 1.5.0"},
      {:postgrex, "~> 0.15.0"},
      {:sentry, "~> 8.0"},
      {:sweet_xml, "~> 0.6"},
      {:tzdata, "~> 1.1.0"},
      {:uuid, "~> 1.1.8"},
      {:bypass, "~> 2.1.0", only: :test},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:exvcr, "~> 0.14.1", only: :test}
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

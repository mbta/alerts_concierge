defmodule ConciergeSite.Mixfile do
  use Mix.Project

  def project do
    [
      app: :concierge_site,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
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
    extra = [:logger, :runtime_tools]
    extra = if(Mix.env() == :prod, do: extra ++ [:diskusage_logger, :ehmon], else: extra)
    [mod: {ConciergeSite, []}, extra_applications: extra]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:alert_processor, in_umbrella: true},
      {:bamboo, "~> 2.3"},
      {:bamboo_phoenix, "~> 1.0.0"},
      {:bamboo_ses, "~> 0.4"},
      {:ex_aws_sns, "~> 2.3.1"},
      {:gettext, "~> 0.11"},
      {:guardian, "~> 2.3.1"},
      {:guardian_db, "~> 2.1.0"},
      {:hammer, "~> 6.0"},
      {:httpoison, "~> 2.2.1"},
      {:logster, "~> 1.1.1"},
      {:phoenix, "~> 1.6.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.20.14"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 2.0"},
      {:recaptcha, "~> 3.0"},
      {:remote_ip, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:tzdata, "~> 1.1.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:bcrypt_elixir, "~> 3.0", only: :test},
      {:diskusage_logger, "~> 0.2.0", only: :prod},
      {:ehmon, github: "mbta/ehmon", only: :prod},
      {:mjml, "~> 3.1.0"},
      {:ueberauth, "~> 0.10.3"},
      {:ueberauth_oidcc, "~> 0.1"}
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

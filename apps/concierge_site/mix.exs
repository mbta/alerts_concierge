defmodule ConciergeSite.Mixfile do
  use Mix.Project

  def project do
    [app: :concierge_site,
     version: "0.0.10",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     preferred_cli_env: [coveralls: :test, "coveralls.json": :test],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [plt_add_deps: :transitive],
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {ConciergeSite, []},
     extra_applications: [:alert_processor, :logger, :logger_logentries_backend, :runtime_tools]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:alert_processor, in_umbrella: true},
      {:bodyguard, "~> 1.0.0"},
      {:comeonin, "~> 3.0"},
      {:dialyxir, "~> 0.5.0", only: [:dev]},
      {:excoveralls, "~> 0.5", only: [:dev, :test]},
      {:guardian, "~> 0.14"},
      {:guardian_db, "~> 0.8.0"},
      {:phoenix, "~> 1.3.0-rc", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"}
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

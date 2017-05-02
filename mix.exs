defmodule MbtaServer.Mixfile do
  use Mix.Project

  def project do
    [app: :mbta_server,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     dialyzer: [plt_add_deps: :transitive],
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [vcr: :test, coveralls: :test]]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {MbtaServer.Application, []},
      extra_applications: [
        :bamboo,
        :bamboo_smtp,
        :calendar,
        :ex_aws,
        :hackney,
        :httpoison,
        :logger,
        :phoenix_ecto,
        :poison,
        :poolboy,
        :postgrex,
        :runtime_tools,
        :edeliver # Must be at end of list
     ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.3.0"},
      {:bodyguard, "~> 1.0.0"},
      {:calendar, "~> 0.16.1"},
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:dialyxir, "~> 0.5.0", only: [:dev]},
      {:distillery, "1.2.2", warn_missing: false},
      {:edeliver, "1.4.2"},
      {:ex_aws, "~> 1.0"},
      {:excoveralls, "~> 0.5", only: [:dev, :test]},
      {:ex_machina, "~> 2.0", only: :test},
      {:exvcr, "~> 0.8", only: :test},
      {:gettext, "~> 0.11"},
      {:hackney, "~> 1.6"},
      {:httpoison, "~> 0.1"},
      {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:phoenix_pubsub, "~> 1.0"},
      {:poison, "~> 2.0"},
      {:poolboy, ">= 0.0.0"},
      {:postgrex, ">= 0.0.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "coveralls.json"]]
  end
end

defmodule ConciergeSite.Mixfile do
  use Mix.Project

  def project do
    [
      app: :concierge_site,
      version: app_version("0.0.59"),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext, :yecc, :leex, :erlang, :elixir, :xref, :app],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_deps: :transitive],
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    apps = [
      :elixir_make,
      :public_key,
      :crypto,
      :bamboo,
      :logger,
      :runtime_tools
    ]

    apps =
      if Mix.env() == :prod do
        [:sasl, :ehmon, :diskusage_logger | apps]
      else
        apps
      end

    [mod: {ConciergeSite, []}, extra_applications: apps]
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
      {:bamboo, "~> 1.4.0"},
      {:bamboo_ses, "~> 0.1.0"},
      {:comeonin, "~> 3.0"},
      {:dialyxir, "~> 0.5.0", only: [:dev]},
      {:excoveralls, "~> 0.5", only: [:dev, :test]},
      {:guardian, "~> 0.14"},
      {:guardian_db, "~> 0.8.0"},
      {:phoenix, "~> 1.3.4", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:wallaby, "~> 0.23.0", only: :test},
      {:logster, "~> 0.4.0"},
      {:ehmon, github: "mbta/ehmon", only: :prod},
      {:diskusage_logger, "~> 0.2.0", only: :prod},
      {:httpoison, "~> 1.1.1", override: true},
      {:poison, "~> 2.0", override: true},
      {:tzdata, "~> 1.0.0", override: true},
      {:hammer, "~> 6.0"},
      {:hammer_plug, "~> 2.0"},
      {:sentry, "~> 7.0"}
    ]
  end

  defp app_version(base) do
    # get git version
    try do
      case System.cmd("git", ~w[rev-parse HEAD]) do
        {hash, 0} -> "#{base}+#{String.trim(hash)}"
        _ -> base
      end
    rescue
      _ -> base
    end
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

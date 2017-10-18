defmodule AlertProcessor.Mixfile do
  use Mix.Project

  def project do
    [app: :alert_processor,
     version: "0.0.51",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:gettext] ++ Mix.compilers,
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
    [mod: {AlertProcessor, []},
      extra_applications: [
        :system_metrics,
        :elixir_make,
        :ex2ms,
        :plug,
        :jsx,
        :public_key,
        :crypto,
        :calendar,
        :comeonin,
        :sweet_xml, # Must come before ex_aws
        :ex_aws,
        :ex_rated,
        :hackney,
        :httpoison,
        :logger,
        :logger_logentries_backend,
        :poison,
        :poolboy,
        :postgrex,
        :runtime_tools,
        :scrivener_ecto,
        :edeliver,
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
      {:calendar, "~> 0.16.1"},
      {:comeonin, "~> 3.0"},
      {:cowboy, "~> 1.0"},
      {:dialyxir, "~> 0.5.0", only: [:dev]},
      {:ecto, "~> 2.1.0"},
      {:excoveralls, "~> 0.5", only: [:dev, :test]},
      {:ex_aws, git: "https://github.com/bfauble/ex_aws", ref: "f64f2cb026171dc6def03102ccae31906797deb0"},
      {:ex_machina, "~> 2.0", only: :test},
      {:ex_rated, "~> 1.3"},
      {:exvcr, "~> 0.8", runtime: :false},
      {:gettext, "~> 0.11"},
      {:hackney, "~> 1.6"},
      {:httpoison, "~> 0.1"},
      {:paper_trail, "~> 0.7.5"},
      {:poison, "~> 2.0"},
      {:poolboy, ">= 0.0.0"},
      {:postgrex, ">= 0.0.0"},
      {:scrivener_ecto, "~> 1.0"},
      {:sweet_xml, "~> 0.6"},
      {:system_metrics, in_umbrella: true},
      {:edeliver, "1.4.3"}
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

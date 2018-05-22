defmodule AlertProcessor.Mixfile do
  use Mix.Project

  def project do
    [app: :alert_processor,
     version: "0.0.59",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.6",
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
        :elixir_make,
        :ex2ms,
        :plug,
        :jsx,
        :public_key,
        :crypto,
        :calendar,
        :comeonin,
        :sweet_xml, # Must come before ex_aws
        :exactor,
        :ex_aws,
        :ex_rated,
        :hackney,
        :httpoison,
        :logger,
        :poison,
        :poolboy,
        :postgrex,
        :runtime_tools,
        :scrivener_ecto,
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
      {:bamboo, "~> 0.8", only: [:test]},
      {:bamboo_smtp, "~> 1.3.0", only: [:test]},
      {:calendar, "~> 0.17.2"},
      {:comeonin, "~> 3.0"},
      {:cowboy, "~> 1.0"},
      {:dialyxir, "~> 0.5.0", only: [:dev]},
      {:ecto, "~> 2.1.0"},
      {:exactor, "~> 2.2.0"},
      {:excoveralls, "~> 0.5", only: [:dev, :test]},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sns, git: "https://github.com/ex-aws/ex_aws_sns", ref: "7a681400876774cf8ea9825a07b7d361715e4362"},
      {:ex_machina, "~> 2.0", only: :test},
      {:ex_rated, "~> 1.3"},
      {:exvcr, "~> 0.10.1", runtime: :false},
      {:gettext, "~> 0.11"},
      {:hackney, "~> 1.12", override: true},
      {:httpoison, "~> 1.1.1", override: true},
      {:paper_trail, "~> 0.7.5"},
      {:poison, "~> 2.0"},
      {:poolboy, ">= 0.0.0"},
      {:postgrex, ">= 0.0.0"},
      {:scrivener_ecto, "~> 1.0"},
      {:sweet_xml, "~> 0.6"},
      {:eflame, "~> 1.0", only: [:dev]}
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

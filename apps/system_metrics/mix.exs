defmodule SystemMetrics.Mixfile do
  use Mix.Project

  def project do
    [app: :system_metrics,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {SystemMetrics, []},
     applications: [
       :sasl,
       :os_mon,
       :lager,
       :logger,
       :elixometer,
       :exometer_datadog
     ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:plug, ">= 0.0.0"},
     {:poison, "~> 2.0", [override: true]},
     {:exometer_datadog, "~> 0.4.0"},
     {:elixometer, github: "pinterest/elixometer"},
     {:exometer, github: "Feuerlabs/exometer"},
     {:exometer_core, "~>1.4.0", override: true},
     {:lager, ">= 3.2.1", [hex: :lager, override: true]},
     {:amqp_client, override: true},
     {:amqp, "~> 0.1.4"},
     {:excoveralls, "~> 0.5", only: :test}]
  end
end

# System Metrics

A component for registering metrics about the application for rendering on a dashboard.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `system_metrics` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:system_metrics, "~> 0.1.0"}]
    end
    ```

  2. Ensure `system_metrics` is started before your application:

    ```elixir
    def application do
      [applications: [:system_metrics]]
    end
    ```

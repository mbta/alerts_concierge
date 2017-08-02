# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: :prod

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: "APP_COOKIE" |> System.get_env() |> String.to_atom()
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :alert_processor do
  set version: current_version(:alert_processor)
  set output_dir: "./releases/alert_processor"
  set applications: [
    :alert_processor
  ]
  plugin Releases.Plugin.LinkConfig
end

release :concierge_site do
  set version: current_version(:concierge_site)
  set output_dir: "./releases/concierge_site"
  set applications: [
    :concierge_site
  ]
  plugin Releases.Plugin.LinkConfig
end

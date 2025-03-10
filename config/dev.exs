import Config

config :ueberauth, Ueberauth,
  providers: [
    keycloak: {Ueberauth.Strategy.FakeKeycloak, []},
    register: {Ueberauth.Strategy.FakeKeycloak, []}
  ]

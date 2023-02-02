import Config

config :ueberauth, Ueberauth,
  providers: [
    keycloak: {Draft.Ueberauth.Strategy.FakeKeycloak, []}
  ]

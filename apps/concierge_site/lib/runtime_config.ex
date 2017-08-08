defmodule ConciergeSite.RuntimeConfig do
  @moduledoc "Set runtime config for deps that can't be set in config.exs"

  def set_runtime_config do
    set_logentries()
    set_smtp()
    set_guardian()
    set_endpoint()
  end

  defp set_logentries do
    env = Enum.into(Application.get_env(:logger, :logentries), %{})
    token = System.get_env("LOGENTRIES_TOKEN")
    new_env = Map.put(env, :token, token)
    Application.put_env(:logger, :logentries, new_env)
  end

  defp set_smtp do
    env = Application.get_env(:concierge_site, ConciergeSite.Dissemination.Mailer)
    new_env = Keyword.merge(env, [
      username: System.get_env("SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD")
    ])

   Application.put_env(:concierge_site,
     ConciergeSite.Dissemination.Mailer,
     new_env
   )
  end

  defp set_guardian do
    env = Application.get_env(:guardian, Guardian)
    token = System.get_env("GUARDIAN_AUTH_KEY")
    new_env = Keyword.put(env, :secret_key, token)
    Application.put_env(
      :guardian,
      Guardian,
      new_env
    )
  end

  defp set_endpoint do
    env = Application.get_env(:concierge_site, ConciergeSite.Endpoint)
    new_env = Keyword.merge(env, [
      secret_key_base: System.get_env("SECRET_KEY_BASE"),
      url: [host: System.get_env("HOST_URL"), port: 80]
    ])
    Application.put_env(
      :concierge_site,
      ConciergeSite.Endpoint,
      new_env
    )
  end
end

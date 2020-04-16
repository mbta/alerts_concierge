{:ok, _} = Application.ensure_all_started(:ex_machina)
:hackney_trace.disable()

ExUnit.configure(exclude: [pending: true])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, :manual)

%{
  configs: [
    %{
      name: "default",
      checks: [
        # Disable some checks enabled by default
        {Credo.Check.Consistency.ExceptionNames, false},
        {Credo.Check.Refactor.Nesting, false},
        {Credo.Check.Refactor.PipeChainStart, false},
        # Note: Enable and switch to `compile_env` after upgrading Elixir
        {Credo.Check.Warning.ApplicationConfigInModuleAttribute, false},

        # Enable some experimental opt-in checks
        {Credo.Check.Refactor.AppendSingleItem},
        {Credo.Check.Warning.MapGetUnsafePass}
      ]
    }
  ]
}

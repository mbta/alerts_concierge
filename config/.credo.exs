%{
  configs: [
    %{
      name: "default",
      checks: [
        # Disable some checks enabled by default
        {Credo.Check.Consistency.ExceptionNames, false},
        {Credo.Check.Refactor.Nesting, false},

        # Enable some experimental opt-in checks
        {Credo.Check.Design.SkipTestWithoutComment},
        {Credo.Check.Readability.SingleFunctionToBlockPipe},
        {Credo.Check.Refactor.AppendSingleItem},
        {Credo.Check.Refactor.IoPuts},
        {Credo.Check.Warning.MapGetUnsafePass}
      ]
    }
  ]
}

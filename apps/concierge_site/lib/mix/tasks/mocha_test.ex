defmodule Mix.Tasks.MochaTest do
  @moduledoc false
  use Mix.Task

  @shortdoc "Run the front end mocha javascript tests"

  def run(_) do
    "npm"
    |> System.cmd(
        ["--prefix", "apps/concierge_site/assets", "test"],
        into: IO.stream(:stdio, :line)
       )
    |> handle_test_result
  end

  defp handle_test_result({_result, 0}), do: IO.puts("All mocha tests have passed.")

  defp handle_test_result(_) do
    IO.puts "Mocha tests did not pass."
    exit({:shutdown, 1})
  end
end

defmodule Mix.Tasks.MochaTest do
  use Mix.Task

  @shortdoc "Run the front end mocha javascript tests"

  def run(_) do
    System.cmd("npm", ["--prefix", "apps/concierge_site/assets", "test"], into: IO.stream(:stdio, :line))
  end
end

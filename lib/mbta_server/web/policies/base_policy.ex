defmodule MbtaServer.BasePolicy do
  @moduledoc """
  Base policy configuration to extend policies from
  """
  
  alias MbtaServer.{User}
  import Ecto.Query

  # Admin users have full control by default
  def can?(%User{role: "admin"}, _action, _resource), do: true

  # Regular user cannot access anything by default
  def can?(%User{id: user_id, role: "user"}, _action, _resource), do: false

  # Catch-all: deny everything else
  def can?(_, _, _), do: false

  # Admin can see all resources
  def scope(%User{role: "admin"}, _action, scope), do: scope

  # User sees nothing by default
  def scope(%User{role: "user", id: id}, _action, _scope), do: []

  # Unauthenticated user see nothing by default
  def scope(nil, _action, scope), do: []
end

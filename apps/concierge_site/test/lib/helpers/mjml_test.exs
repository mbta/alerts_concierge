defmodule ConciergeSite.MJMLTest do
  @moduledoc false
  use ConciergeSite.DataCase, async: true
  alias ConciergeSite.MJML
  require ConciergeSite.MJML

  test "works properly with EEx tags" do
    assert {:ok, result} =
             MJML.eval_string(
               """
               <mjml>
                 <mj-body>
                   <%= if value do %>
                     <%= value %>
                   <% end %>
                 </mj-body>
               </mjml>
               """,
               value: "needle"
             )

    assert result =~ "needle"
  end

  MJML.function_from_template(
    :defp,
    :test_template,
    "test.mjml",
    [:value]
  )

  describe "function_from_template/3" do
    test "creates a working function in the module scope" do
      assert test_template("needle") =~ "needle"
    end
  end
end

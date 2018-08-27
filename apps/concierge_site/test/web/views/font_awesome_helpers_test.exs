defmodule ConciergeSite.FontAwesomeHelpersTest do
  use ConciergeSite.ConnCase, async: true
  alias ConciergeSite.FontAwesomeHelpers

  describe "fa/2" do
    test "creates the HTML for a FontAwesome icon" do
      expected = ~s(<i aria-hidden="true" class="fa fa-arrow-right "></i>)

      result = FontAwesomeHelpers.fa("arrow-right")

      assert Phoenix.HTML.safe_to_string(result) == expected
    end

    test "when optional attributes are included" do
      expected = ~s(<i aria-hidden="true" class="fa fa-arrow-right foo" title="title"></i>)

      result = FontAwesomeHelpers.fa("arrow-right", class: "foo", title: "title")

      assert Phoenix.HTML.safe_to_string(result) == expected
    end
  end
end

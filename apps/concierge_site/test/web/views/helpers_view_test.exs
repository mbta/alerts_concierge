defmodule ConciergeSite.ViewHelpersTest do
  use ConciergeSite.ConnCase, async: true
  import ConciergeSite.ViewHelpers

  describe "google_tag_manager_id/0" do
    test "returns environment variable" do
      assert google_tag_manager_id() == "GOOGLE_TAG_MANAGER_ID"
    end
  end
end

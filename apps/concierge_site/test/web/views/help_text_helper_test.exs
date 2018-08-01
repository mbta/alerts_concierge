defmodule ConciergeSite.HelpTextHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.HelpTextHelper

  test "link/1" do
    html = Phoenix.HTML.safe_to_string(HelpTextHelper.link("test"))

    assert html =~
             "<a class=\"helptext__link\" data-message-id=\"test\" data-type=\"help-link\" href=\"#show\">"
  end

  test "message/2" do
    html = Phoenix.HTML.safe_to_string(HelpTextHelper.message("test", "This is a help message."))

    assert html ==
             "<div class=\"helptext__message\" data-message-id=\"test\" data-type=\"help-message\"><a class=\"helptext__message--close\" data-message-id=\"test\" data-type=\"close-help-text\" href=\"#close\"><i class=\"fa fa-times-circle helptext__message--close-icon\"></i></a>This is a help message.</div>"
  end
end

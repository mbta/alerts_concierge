defmodule MbtaServer.Web.LayoutView do
  use MbtaServer.Web, :view

  def get_page_classes(module, template) do
    module_class = module
    |> Module.split
    |> Enum.slice(1..-1)
    |> Enum.join("-")
    |> String.downcase

    template_class = template |> String.replace(".html", "-template")

    "#{module_class} #{template_class}"
  end
end

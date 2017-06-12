defmodule Mix.Tasks.Compile.AlertMail do
  use Mix.Task

  @base_dir Path.join(~w(#{System.cwd!} lib mail_templates))
  @output_dir Path.join(~w(#{@base_dir} output))
  @template_dir Path.join(~w(#{@base_dir} precompiled))
  @command "#{System.cwd!}/mail_inlining/inline_css.js"

  def run(_args) do
    build_templates_with_inline_css(["digest", "notification", "_header", "_footer"])
   :ok
  end

  defp build_templates_with_inline_css(template_names) do
    Enum.each(template_names, &build_template_with_inline_css/1)
  end

  defp build_template_with_inline_css(template_name) do

    template_path = Path.join([@template_dir, template_name]) <> "_base.html.eex"
    style_path = Path.join([@template_dir, template_name]) <> "_styles.css"
    output_template = Path.join([@output_dir, template_name]) <>  ".html.eex"

    {output_html, 0} = inline_css(template_path, style_path)

    File.write!(output_template, output_html, [:write])
  end

  defp inline_css(template_path, style_path) do
    html = "--htmlFile=" <> template_path
    css = "--cssFile=" <> style_path
    System.cmd("node", [@command, html, css])
  end
end

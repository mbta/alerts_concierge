defmodule Mix.Tasks.Compile.AlertMail do
  use Mix.Task

  @template_dir Path.join(~w(#{System.cwd!} lib mail_templates))
  @output_dir Path.join(~w(#{System.cwd!} generated_templates))
  @style_dir Path.join(~w(#{@template_dir} styles))
  @command "#{System.cwd!}/mail_inlining/inline_css.js"

  def run(_args) do
    build_templates_with_inline_css(template_files())
   :ok
  end

  defp template_files do
    File.ls!(@template_dir)
    |> Enum.filter_map(&(String.ends_with?(&1, ".html.eex")), &(String.replace_suffix(&1, ".html.eex", "")))
  end

  defp build_templates_with_inline_css(template_names) do
    Enum.each(template_names, &build_template_with_inline_css/1)
  end

  defp build_template_with_inline_css(template_name) do
    template_path = Path.join([@template_dir, template_name]) <> ".html.eex"
    style_path = Path.join([@style_dir, template_name]) <> "_styles.css"
    global_path = @style_dir <> "/_global_styles.css"
    output_template = Path.join([@output_dir, template_name]) <> ".html.eex"

   {output_html, 0} = inline_css(template_path, style_path, global_path)

    File.write!(output_template, output_html, [:write])
  end

  defp inline_css(template_path, style_path, global_path) do
    html = "--htmlFile=" <> template_path
    css = "--cssFile=" <> style_path
    global = "--globalCssFile=" <> global_path
    System.cmd("node", [@command, html, css, global])
  end
end

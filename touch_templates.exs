defmodule TouchTemplates do
  @template_dir Path.join(~w(#{System.cwd!} apps alert_processor lib mail_templates))
  @output_dir Path.join(~w(#{System.cwd!} apps alert_processor generated_templates))

  def run!() do
    IO.inspect "Touching generated_templates"
    template_files()
    |> Enum.each(&touch_if_not_present/1)
  end

  defp template_files do
    @template_dir
    |> File.ls!()
    |> Enum.filter(&(String.ends_with?(&1, ".html.eex")))
    |> Enum.map(&(String.replace_suffix(&1, ".html.eex", "")))
  end

  defp touch_if_not_present(template_name) do
    file = Path.join([@output_dir, template_name]) <> ".html.eex"
    IO.inspect file

    write_base_content(file)
  end

  defp write_base_content(file) do
    cond do
      String.ends_with?(file, "digest.html.eex") -> insert_content(file, :digest)
      String.ends_with?(file, "notification.html.eex") -> insert_content(file, :notification)
      String.ends_with?(file, "footer.html.eex") -> insert_content(file, :footer)
      true -> File.touch!(file)
    end
  end

  defp insert_content(file, :digest) do
    content = "<%= digest_date_groups %><%= unsubscribe_url %>"
    File.write!(file, content)
  end
  defp insert_content(file, :notification) do
    content = "<%= notification %><%= unsubscribe_url %>"
    File.write!(file, content)
  end
  defp insert_content(file, :footer) do
    content = "<%= unsubscribe_url %>"
    File.write!(file, content)
  end
end

TouchTemplates.run!

defmodule ConciergeSite.MJML do
  @moduledoc """
  Utilities to make working with our MJML templates similar to working with
  typical EEx templates.
  """

  @template_dir Application.compile_env!(:concierge_site, :mjml_template_dir)

  @spec template_path(Path.t()) :: Path.t()
  def template_path(name) do
    Path.join(@template_dir, name)
  end

  # NOTE(Nick): This escape/unescape is necessary since the underlying MJML
  # library we rely on doesn't support arbitrary junk properly inside
  # <mjml-raw> tags. See https://github.com/jdrouet/mrml/issues/252 for an
  # issue tracking this.

  defp escape_eex(contents) do
    contents = Regex.replace(~r/<%/, contents, "EEX_LHS_ESCAPED")

    Regex.replace(~r/%>/, contents, "EEX_RHS_ESCAPED")
  end

  defp unescape_eex(contents) do
    contents = Regex.replace(~r/EEX_LHS_ESCAPED/, contents, "<%")

    Regex.replace(~r/EEX_RHS_ESCAPED/, contents, "%>")
  end

  @spec to_html_with_eex(String.t()) :: {:ok, String.t()} | {:error, any()}
  defp to_html_with_eex(contents) do
    case Mjml.to_html(escape_eex(contents)) do
      {:ok, contents} -> {:ok, unescape_eex(contents)}
      e -> e
    end
  end

  @spec html_from_template(Path.t()) :: {:ok, String.t()} | {:error, any()}
  defp html_from_template(name) do
    path = template_path(name)

    case File.read(path) do
      {:ok, contents} ->
        to_html_with_eex(contents)

      e ->
        e
    end
  end

  @spec compile_template(Path.t(), keyword) :: {:ok, Macro.t()} | {:error, any()}
  def compile_template(name, options \\ []) do
    case html_from_template(name) do
      {:ok, html} -> {:ok, EEx.compile_string(html, options)}
      e -> e
    end
  end

  @spec eval_string(String.t(), keyword, keyword) :: {:ok | :error, String.t()}
  def eval_string(mjml_string, bindings \\ [], options \\ []) do
    case to_html_with_eex(mjml_string) do
      {:ok, html} -> {:ok, EEx.eval_string(html, bindings, options)}
      e -> e
    end
  end

  @spec function_from_template(:defp | :def, atom(), Path.t(), [atom()], keyword) :: Macro.t()
  defmacro function_from_template(kind, name, template, args \\ [], options \\ []) do
    quote bind_quoted: binding() do
      file = ConciergeSite.MJML.template_path(template)
      info = Keyword.merge([file: file, line: 1], options)
      {:ok, compiled} = ConciergeSite.MJML.compile_template(template, info)
      args = Enum.map(args, fn arg -> {arg, [line: 1], nil} end)

      arg_types =
        Enum.map(args, fn _ ->
          quote line: 1 do
            any()
          end
        end)

      @external_resource file
      @file file
      @spec unquote(name)(unquote_splicing(arg_types)) :: String.t()
      case kind do
        :def -> def unquote(name)(unquote_splicing(args)), do: unquote(compiled)
        :defp -> def unquote(name)(unquote_splicing(args)), do: unquote(compiled)
      end
    end
  end

  @mail_template_dir Application.compile_env!(:concierge_site, :mail_template_dir)
  def html_template_path(name) do
    Path.join(@mail_template_dir, name)
  end

  def overwrite_html_template!(mjml_name, html_name) do
    {:ok, html} = html_from_template(mjml_name)

    File.write!(html_template_path(html_name), html)
  end

  def overwrite_html_templates!() do
    overwrite_html_template!("notification.mjml", "notification.html.eex")
    overwrite_html_template!("password-reset.mjml", "password_reset.html.eex")
    overwrite_html_template!("confirmation.mjml", "confirmation.html.eex")
  end
end

defmodule ConciergeSite.Dissemination.NotificationEmail do
  @moduledoc "Bamboo Mailer interface"
  import Bamboo.Email
  import AlertProcessor.Helpers.StringHelper, only: [capitalize_first: 1]
  alias AlertProcessor.Model.Notification
  alias ConciergeSite.Dissemination.Email
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  EEx.function_from_file(:def, :html_email, Path.join(@template_dir, "notification.html.eex"), [
    :notification,
    :manage_subscriptions_url,
    :feedback_url
  ])

  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!()} lib mail_templates notification.txt.eex)),
    [:notification, :manage_subscriptions_url, :feedback_url]
  )

  @doc "notification_email/1 takes a notification and builds an email to be sent to user."
  @spec notification_email(Notification.t()) :: Elixir.Bamboo.Email.t()
  def notification_email(%Notification{email: email} = notification) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url()
    feedback_url = MailHelper.feedback_url()
    notification_email_subject = email_subject(notification)

    Email.base_email()
    |> to(email)
    |> subject(notification_email_subject)
    |> html_body(html_email(notification, manage_subscriptions_url, feedback_url))
    |> text_body(text_email(notification, manage_subscriptions_url, feedback_url))
  end

  def email_subject(notification) do
    {_, subject} =
      {notification, ""}
      |> subject_body()
      |> subject_prefix()
      |> subject_suffix()
      |> subject_closed()

    subject
  end

  defp subject_body({%Notification{service_effect: effect} = notification, subject}) do
    {notification, "#{subject}#{effect}"}
  end

  defp subject_prefix({%Notification{alert: %{timeframe: nil}}, _} = pair), do: pair

  defp subject_prefix({%Notification{alert: %{timeframe: timeframe}} = notification, subject}) do
    {notification, "#{capitalize_first(timeframe)}: #{subject}"}
  end

  defp subject_suffix({%Notification{alert: %{recurrence: nil}}, _} = pair), do: pair

  defp subject_suffix({%Notification{alert: %{recurrence: recurrence}} = notification, subject}) do
    {notification, "#{subject} #{recurrence}"}
  end

  defp subject_closed({%Notification{type: :all_clear} = notification, subject}) do
    {notification, "All clear (re: #{subject})"}
  end

  defp subject_closed({%Notification{type: :update} = notification, subject}) do
    {notification, "Update (re: #{subject})"}
  end

  defp subject_closed({%Notification{type: :reminder} = notification, subject}) do
    {notification, "Reminder (re: #{subject})"}
  end

  defp subject_closed({_, _} = pair), do: pair
end

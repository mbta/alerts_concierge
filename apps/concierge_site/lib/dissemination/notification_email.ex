defmodule ConciergeSite.Dissemination.NotificationEmail do
  @moduledoc "Bamboo Mailer interface"
  import Bamboo.Email
  import AlertProcessor.Helpers.StringHelper, only: [capitalize_first: 1]
  alias AlertProcessor.Model.Notification
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @from {ConfigHelper.get_string(:send_from_name, :concierge_site),
         ConfigHelper.get_string(:send_from_email, :concierge_site)}
  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "notification.html.eex"),
    [:notification, :manage_subscriptions_url, :feedback_url])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates notification.txt.eex)),
    [:notification, :manage_subscriptions_url, :feedback_url])

  @doc "notification_email/1 takes a notification and builds an email to be sent to user."
  @spec notification_email(Notification.t) :: Elixir.Bamboo.Email.t
  def notification_email(%Notification{user: user} = notification) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(user)
    feedback_url = MailHelper.feedback_url()
    notification_email_subject = email_subject(notification)

    base_email()
    |> to(user.email)
    |> subject(notification_email_subject)
    |> html_body(html_email(notification, manage_subscriptions_url, feedback_url))
    |> text_body(text_email(notification, manage_subscriptions_url, feedback_url))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email(from: @from)
  end

  def email_subject(notification) do
    {_, subject} = {notification, ""}
    |> subject_body()
    |> subject_prefix()
    |> subject_suffix()
    |> subject_closed()
    |> subject_reminder()

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

  defp subject_closed({%Notification{closed_timestamp: nil}, _} = pair), do: pair
  defp subject_closed({notification, subject}) do
    {notification, "All clear (re: #{subject})"}
  end

  defp subject_reminder({notification, subject} = pair) do
    if notification.reminder? && is_nil(notification.closed_timestamp) do
      {notification, "Reminder (re: #{subject})"}
    else
      pair
    end
  end
end

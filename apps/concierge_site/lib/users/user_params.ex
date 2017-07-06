defmodule ConciergeSite.UserParams do
  @moduledoc """
  Functions for processing user input from account updates and creation
  """

  alias AlertProcessor.Helpers.DateTimeHelper

  @doc """
  Map radio button selections from Update Account page to appropriate user attributes
  """
  @spec prepare_for_update_changeset(map) :: map
  def prepare_for_update_changeset(params) do
    phone_number =
      case params["sms_toggle"] do
        "true" -> %{"phone_number" => params["phone_number"]}
        "false" -> %{"phone_number" => nil}
        _ -> %{}
      end

    do_not_disturb =
      case params["dnd_toggle"] do
        "true" ->
          %{"do_not_disturb_start" => DateTimeHelper.timestamp_to_utc(params["do_not_disturb_start"]), # have to convert time
            "do_not_disturb_end" => DateTimeHelper.timestamp_to_utc(params["do_not_disturb_end"])} # have to convert time
        "false" ->
          %{"do_not_disturb_start" => nil, "do_not_disturb_end" => nil}
        _ -> %{}
      end

    Map.merge(phone_number, do_not_disturb)
  end
end

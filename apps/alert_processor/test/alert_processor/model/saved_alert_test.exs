defmodule AlertProcessor.SavedAlertTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{SavedAlert}

  @valid_attrs %{
    alert_id: "123456",
    last_modified: DateTime.utc_now(),
    data: %{}
  }

  describe "create_changeset" do
    test "with valid attrs" do
      changeset = SavedAlert.create_changeset(%SavedAlert{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires alert_id" do
      attrs = Map.delete(@valid_attrs, :alert_id)
      changeset = SavedAlert.create_changeset(%SavedAlert{}, attrs)
      refute changeset.valid?
    end

    test "requires last_modified" do
      attrs = Map.delete(@valid_attrs, :last_modified)
      changeset = SavedAlert.create_changeset(%SavedAlert{}, attrs)
      refute changeset.valid?
    end

    test "requires data" do
      attrs = Map.delete(@valid_attrs, :data)
      changeset = SavedAlert.create_changeset(%SavedAlert{}, attrs)
      refute changeset.valid?
    end

    test "uniqueness of alert_id" do
      changeset = SavedAlert.create_changeset(%SavedAlert{}, @valid_attrs)
      Repo.insert!(changeset)

      assert {:error, _reason} = Repo.insert(changeset)
    end
  end

  describe "update_changeset" do
    test "with valid attrs" do
      changeset = SavedAlert.create_changeset(%SavedAlert{}, @valid_attrs)
      alert = Repo.insert!(changeset)

      update_params = %{
        data: %{service_effect: "haha"},
        last_modified: DateTime.utc_now()
      }

      update_changeset = SavedAlert.update_changeset(alert, update_params)

      assert update_changeset.valid?
    end
  end

  describe "save_new_alert" do
    test "saves alert with version" do
      saved_alert = SavedAlert.save_new_alert(%SavedAlert{}, @valid_attrs)

      [alert] = Repo.all(SavedAlert)

      assert saved_alert == %{alert | notification_type: :initial}
      assert %PaperTrail.Version{} = PaperTrail.get_version(saved_alert)
    end
  end

  describe "update_existing_alert" do
    test "updates alert with new version" do
      saved_alert = SavedAlert.save_new_alert(%SavedAlert{}, @valid_attrs)

      update_params = %{
        data: %{"service_effect" => "haha"},
        last_modified: DateTime.utc_now()
      }

      updated_alert = SavedAlert.update_existing_alert(saved_alert, update_params)
      [alert] = Repo.all(SavedAlert)

      assert updated_alert == %{alert | notification_type: :update}
      assert [_v1, _v2] = PaperTrail.get_versions(updated_alert)
    end
  end

  @alert1 %{"id" => "1", "last_modified_timestamp" => 1_503_619_200, "data" => %{"test" => 1}}
  @alert2 %{"id" => "2", "last_modified_timestamp" => 1_503_619_200, "data" => %{"test" => 1}}

  @alerts [
    @alert1,
    @alert2
  ]

  describe "save!" do
    test "saves alerts that don't exist" do
      assert [_a1, _a2] = SavedAlert.save!(@alerts)
    end

    test "updates alerts with last_modified changed" do
      [_a1, _a2] = SavedAlert.save!(@alerts)

      updated = [
        %{"id" => "1", "last_modified_timestamp" => 2_000_000_000, "data" => %{"test" => 2}}
      ]

      assert [updated_alert] = SavedAlert.save!(updated)
      assert updated_alert.data["data"]["test"] == 2
    end
  end
end

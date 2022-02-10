defmodule AlertProcessor.Model.MetadataTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.Model.Metadata
  alias AlertProcessor.Repo

  describe "get/1" do
    test "gets the data field of the record with the given key" do
      test_data = %{"some" => ["test", "data"], "with" => "maps"}
      Repo.insert!(%Metadata{id: :test_key, data: test_data})

      assert Metadata.get(:test_key) == test_data
    end

    test "returns an empty map if there is no record for the key" do
      assert Metadata.get(:does_not_exist) == %{}
    end
  end

  describe "put/2" do
    test "inserts a new record with the given data" do
      Metadata.put(:new_test_key, %{"test" => "data"})

      record = Repo.get!(Metadata, :new_test_key)
      assert record.data == %{"test" => "data"}
      assert record.inserted_at
      assert record.updated_at
    end

    test "updates an existing record with the given data" do
      timestamp = ~U[2021-01-01 00:00:00Z]

      Repo.insert!(%Metadata{
        id: :test_key,
        data: %{"test" => "data"},
        inserted_at: timestamp,
        updated_at: timestamp
      })

      Metadata.put(:test_key, %{"new" => "data"})

      record = Repo.get!(Metadata, :test_key)
      assert record.data == %{"new" => "data"}
      assert record.inserted_at == timestamp
      assert record.updated_at != timestamp
    end
  end

  describe "delete/1" do
    test "deletes the record with the given key" do
      Repo.insert!(%Metadata{id: :test_key, data: %{}})

      Metadata.delete(:test_key)

      refute Repo.get(Metadata, :test_key)
    end

    test "does nothing if there is no record with the given key" do
      assert :ok = Metadata.delete(:no_such_key)
    end
  end
end

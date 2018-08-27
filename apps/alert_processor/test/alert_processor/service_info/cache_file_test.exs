defmodule AlertProcessor.ServiceInfo.CacheFileTest do
  use ExUnit.Case, async: true
  alias AlertProcessor.ServiceInfo.CacheFile
  doctest CacheFile

  test "generate_filepath/1 given a filename returns a path" do
    filepath = CacheFile.generate_filepath("foob.ar")
    assert filepath =~ "foob.ar"
    assert filepath =~ "priv/service_info_cache"
  end

  describe "cache_filetest/0" do
    test "returns a filename in test Mix.env" do
      assert CacheFile.cache_filename() == "test_cache.terms"
    end
  end

  describe "load_service_info/1" do
    test "returns {:ok, term} for a map" do
      filepath = CacheFile.generate_filepath("load_service_info_1_test_map.terms")
      term_map = %{load_service_info_1_test: true}
      assert CacheFile.save_service_info(term_map, filepath) == :ok
      assert CacheFile.load_service_info(filepath) == {:ok, term_map}
    end

    test "returns error for non-map" do
      filepath =
        Path.join([
          System.cwd(),
          "priv/service_info_cache",
          "load_service_info_1_test_non_map.terms"
        ])

      payload = [:non_map]
      assert CacheFile.save_service_info(payload, filepath) == {:error, :cache_file_not_saved}
    end
  end

  describe "save_service_info/2" do
    test "saves a file" do
      filepath = CacheFile.generate_filepath("save_service_info_2_test.terms")
      assert CacheFile.save_service_info(%{the_state: true}, filepath) == :ok
    end
  end
end

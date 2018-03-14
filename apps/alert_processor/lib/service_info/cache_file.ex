defmodule AlertProcessor.ServiceInfo.CacheFile do
  alias AlertProcessor.Helpers.EnvHelper
  require Logger

  @directory Path.join([File.cwd!, "priv/service_info_cache"])

  @dev_filename "dev_cache.terms"
  @test_filename "test_cache.terms"
  

  @doc """
  Given a filename generates a filepath for saving cache info file.
  """
  def generate_filepath(filename) when is_binary(filename) do
    Path.join([@directory, filename])
  end

  @doc """
  The application should use the file to load state for the ServiceInfoCache
  if the the envs are :dev or :test.

    iex> Mix.env
    :test
    iex> CacheFile.should_use_file?
    true

  """
  def should_use_file? do
    EnvHelper.is_env?(:dev) || EnvHelper.is_env?(:test)
  end

  @doc """
  The environment specific filepath (path and file name) or nil.
  """
  def cache_filename() do
    cond do
      EnvHelper.is_env?(:dev) -> @dev_filename
      EnvHelper.is_env?(:test) -> @test_filename
      true -> nil
    end
  end

  @doc """
  Attempt to load a cache file.

  This will attempt to load a cache file in dev and test. It will fail
  if the Mix.env is not dev or test, it will fail if the file does not exist
  and it will fail if the loaded term is not a map (minimal validation).

  The validation for loading this file must be appended in later code. No
  such validator currently exists.
  """
  def load_service_info() do
    Logger.info(fn -> "Loading service info cache from default path" end)
    filename = cache_filename()
    filepath = generate_filepath(filename)
    load_service_info(filepath)
  end
  def load_service_info(filepath) when is_binary(filepath) do
    Logger.info(fn -> "Loading service info cache from file #{filepath}" end)
    with \
      {:ok, binary_cache} <- File.read(filepath),
      {:ok, state} when is_map(state) <- binary_to_term(binary_cache)
    do
      Logger.info(fn -> "Loaded service info cache from file #{filepath}" end)
      {:ok, state}
    else
      _ ->
        Logger.info(fn -> "Failed to load service info cache from file #{filepath}" end)
        {:error, :cache_not_loaded}
    end
  end
  def load_service_info(_) do
    Logger.info(fn -> "Failed to load service info cache from file" end)    
    {:error, :cache_not_loaded}    
  end

  @doc """
  Attempt to save a cache file.
  """
  def save_service_info(state) do
    filename = cache_filename()
    if is_binary(filename) do
      filepath = generate_filepath(filename)
      Logger.info(fn -> "Saving service info cache to file #{filepath}" end)
      save_service_info(state, filepath)
    else
      {:error, :cache_file_not_saved}
    end
  end
  def save_service_info(state, filepath) when is_map(state) and is_binary(filepath) do
    bin = :erlang.term_to_binary(state)
    File.write(filepath, bin)
  end
  def save_service_info(_, _) do
    {:error, :cache_file_not_saved}
  end

  defp binary_to_term(bin) do
    try do
      {:ok, :erlang.binary_to_term(bin)}
    rescue
      ArgumentError ->
        {:error, :invalid_erlang_term_binary}
    end
  end

end
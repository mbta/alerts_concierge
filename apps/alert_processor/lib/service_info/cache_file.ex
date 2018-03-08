defmodule AlertProcessor.ServiceInfo.CacheFile do
  alias AlertProcessor.Helpers.EnvHelper

  @directory "priv/service_info_cache"

  @dev_filepath Path.join([System.cwd, @directory, "dev_cache.terms"])
  @test_filepath Path.join([System.cwd, @directory, "test_cache.terms"])

  def should_use_file? do
    EnvHelper.is_env?(:dev) || EnvHelper.is_env?(:test)
  end

  def cache_filepath() do
    cond do
      EnvHelper.is_env?(:dev) -> @dev_filepath
      EnvHelper.is_env?(:test) -> @test_filepath
      true -> nil
    end
  end

  def load_service_info() do
    with \
      filepath when is_binary(filepath) <- cache_filepath(),
      {:ok, binary_cache} <- File.read(filepath),
      {:ok, state} when is_map(state) <- binary_to_term(binary_cache)
    do
      {:ok, state}
    else
      _ ->
        {:error, :cache_not_loaded}
    end
  end

  def save_service_info(state) do
    filepath = cache_filepath()
    if is_binary(filepath) do
      save_service_info(state, filepath)
    else
      {:error, :cache_file_not_saved}
    end
  end
  def save_service_info(state, filepath) when is_map(state) and is_binary(filepath) do
    bin = :erlang.term_to_binary(state)
    File.write(filepath, bin)
    |> IO.inspect(label: filepath)
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
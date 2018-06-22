defmodule AlertProcessor.CachedApiClient do
  alias AlertProcessor.ApiClient
  alias AlertProcessor.Model.TripInfo

  @cache_name :api_cache

  @doc ~S"""
  Returns the name of the cache

  ## Examples

      iex> ApiCache.cache_name()
      :api_cache
  """
  def cache_name(), do: @cache_name

  @spec schedule_for_trip(TripInfo.id) :: {:ok, [map]} | {:error, String.t}
  def schedule_for_trip(trip_id) do
    get_or_store("schedule_for_trip-#{trip_id}", fn () -> ApiClient.schedule_for_trip(trip_id) end)
  end

  @spec get_or_store(ConCache.key, ConCache.store_fun) :: ConCache.value
  defp get_or_store(key, api_request_function) do
    ConCache.get_or_store(@cache_name, key, api_request_function)
  end

end

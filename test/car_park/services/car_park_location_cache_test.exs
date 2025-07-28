defmodule CarPark.Services.CarParkLocationCacheTest do
  use ExUnit.Case, async: false
  alias CarPark.Services.CarParkLocationCache

  setup do
    # Cache is already started by the application
    :ok
  end

  describe "get_all_locations/0" do
    test "returns all cached car park locations" do
      locations = CarParkLocationCache.get_all_locations()

      assert is_list(locations)
      assert length(locations) > 0

      # Check that locations have the expected structure
      first_location = List.first(locations)
      assert first_location.carpark_number != nil
      assert first_location.address != nil
      assert first_location.latitude != nil
      assert first_location.longitude != nil
      assert is_float(first_location.latitude)
      assert is_float(first_location.longitude)

      # Verify coordinates are within Singapore bounds
      assert first_location.latitude >= 1.0 and first_location.latitude <= 2.0
      assert first_location.longitude >= 103.0 and first_location.longitude <= 105.0
    end
  end

  describe "get_location/1" do
    test "returns specific location by carpark number" do
      locations = CarParkLocationCache.get_all_locations()
      first_location = List.first(locations)

      found_location = CarParkLocationCache.get_location(first_location.carpark_number)

      assert found_location != nil
      assert found_location.carpark_number == first_location.carpark_number
      assert found_location.address == first_location.address
    end

    test "returns nil for non-existent carpark number" do
      location = CarParkLocationCache.get_location("NONEXISTENT")
      assert location == nil
    end
  end

  describe "get_cache_stats/0" do
    test "returns cache statistics" do
      stats = CarParkLocationCache.get_cache_stats()

      assert stats.total_locations > 0
      assert stats.loaded_at != nil
      assert is_struct(stats.loaded_at, DateTime)
    end
  end

  describe "reload_cache/0" do
    test "reloads the cache successfully" do
      initial_stats = CarParkLocationCache.get_cache_stats()

      {:ok, count} = CarParkLocationCache.reload_cache()

      assert count > 0

      new_stats = CarParkLocationCache.get_cache_stats()
      assert new_stats.total_locations == count
      assert DateTime.compare(new_stats.loaded_at, initial_stats.loaded_at) == :gt
    end
  end

  describe "coordinate conversion" do
    test "converts SVY21 coordinates to valid WGS84 coordinates" do
      locations = CarParkLocationCache.get_all_locations()

      # Check that all locations have valid coordinates
      Enum.each(locations, fn location ->
        assert location.latitude >= -90 and location.latitude <= 90
        assert location.longitude >= -180 and location.longitude <= 180

        # Check that coordinates are within Singapore bounds
        assert location.latitude >= 1.0 and location.latitude <= 2.0
        assert location.longitude >= 103.0 and location.longitude <= 105.0
      end)
    end
  end
end

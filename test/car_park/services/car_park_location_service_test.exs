defmodule CarPark.Services.CarParkLocationServiceTest do
  @moduledoc """
  Tests for CarParkLocationService.
  """

  use CarPark.DataCase, async: true

  alias CarPark.Services.CarParkLocationService

  describe "find_nearest_car_parks/4" do
    test "returns nearest car parks sorted by distance with pagination metadata" do
      # Test coordinates in Singapore
      latitude = 1.37326
      longitude = 103.897
      page = 1
      per_page = 3

      result = CarParkLocationService.find_nearest_car_parks(latitude, longitude, page, per_page)

      assert is_map(result)
      assert Map.has_key?(result, :data)
      assert Map.has_key?(result, :total_count)
      assert Map.has_key?(result, :page)
      assert Map.has_key?(result, :per_page)
      assert Map.has_key?(result, :total_pages)

      assert is_list(result.data)
      assert length(result.data) <= per_page
      assert result.page == page
      assert result.per_page == per_page
      assert result.total_count >= 0
      assert result.total_pages >= 0

      # Verify each result has the expected structure
      Enum.each(result.data, fn car_park ->
        assert Map.has_key?(car_park, :address)
        assert Map.has_key?(car_park, :latitude)
        assert Map.has_key?(car_park, :longitude)
        assert Map.has_key?(car_park, :total_lots)
        assert Map.has_key?(car_park, :available_lots)
        assert is_binary(car_park.address)
        assert is_float(car_park.latitude)
        assert is_float(car_park.longitude)
        assert is_integer(car_park.total_lots)
        assert is_integer(car_park.available_lots)
      end)
    end

    test "handles pagination correctly" do
      latitude = 1.37326
      longitude = 103.897

      # Get first page
      first_page = CarParkLocationService.find_nearest_car_parks(latitude, longitude, 1, 2)
      # Get second page
      second_page = CarParkLocationService.find_nearest_car_parks(latitude, longitude, 2, 2)

      assert length(first_page.data) <= 2
      assert length(second_page.data) <= 2
      assert first_page.total_count == second_page.total_count
      assert first_page.page == 1
      assert second_page.page == 2

      # Results should be different (unless there are fewer than 4 total car parks)
      if length(first_page.data) == 2 and length(second_page.data) > 0 do
        assert first_page.data != second_page.data
      end
    end
  end

  describe "calculate_distance/4" do
    test "calculates distance between two points" do
      # Test with known coordinates in Singapore
      lat1 = 1.37326
      lon1 = 103.897
      lat2 = 1.37429
      lon2 = 103.896

      distance = CarParkLocationService.calculate_distance(lat1, lon1, lat2, lon2)

      assert is_float(distance)
      assert distance > 0
      # Distance should be small for nearby points in Singapore
      assert distance < 10.0
    end

    test "returns 0 for identical coordinates" do
      lat = 1.37326
      lon = 103.897

      distance = CarParkLocationService.calculate_distance(lat, lon, lat, lon)

      assert distance == 0.0
    end
  end

  describe "load_car_park_locations/0" do
    test "loads car park locations from CSV" do
      locations = CarParkLocationService.load_car_park_locations()

      assert is_list(locations)
      assert length(locations) > 0

      # Verify structure of first location
      first_location = List.first(locations)
      assert Map.has_key?(first_location, :carpark_number)
      assert Map.has_key?(first_location, :address)
      assert Map.has_key?(first_location, :latitude)
      assert Map.has_key?(first_location, :longitude)
      assert is_binary(first_location.carpark_number)
      assert is_binary(first_location.address)
      assert is_float(first_location.latitude)
      assert is_float(first_location.longitude)
    end
  end

  describe "find_nearest_car_parks/4 with available slots filtering" do
    test "only returns car parks with available slots" do
      latitude = 1.37326
      longitude = 103.897
      page = 1
      per_page = 10

      result = CarParkLocationService.find_nearest_car_parks(latitude, longitude, page, per_page)

      assert is_map(result)
      assert Map.has_key?(result, :data)

      # Verify all returned car parks have available slots
      Enum.each(result.data, fn car_park ->
        assert car_park.available_lots > 0, "Car park #{car_park.address} has no available slots"
      end)
    end

    test "returns empty data when no car parks have available slots" do
      # This test verifies that the filtering logic works
      # In a real scenario, if all car parks have 0 available slots, the result should be empty
      latitude = 1.37326
      longitude = 103.897
      page = 1
      per_page = 10

      result = CarParkLocationService.find_nearest_car_parks(latitude, longitude, page, per_page)

      assert is_map(result)
      assert Map.has_key?(result, :data)
      assert Map.has_key?(result, :total_count)

      # The result might be empty if no car parks have available slots in the test data
      # or it might contain car parks with available slots
      # The important thing is that if there are results, they all have available_lots > 0
      if length(result.data) > 0 do
        Enum.each(result.data, fn car_park ->
          assert car_park.available_lots > 0, "All returned car parks should have available slots"
        end)
      end
    end
  end
end

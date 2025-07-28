# Start ExUnit directly to avoid test helper Ecto configuration
ExUnit.start()

defmodule CarPark.Services.CarParkLocationCacheSimpleTest do
  use ExUnit.Case, async: false

  alias CarPark.Services.CarParkLocationCache

  # Test the coordinate conversion function directly
  describe "coordinate conversion" do
    test "converts SVY21 coordinates to valid WGS84 coordinates" do
      # Test with a known SVY21 coordinate from Singapore
      # This is a sample coordinate from the CSV file
      # SVY21 X coordinate
      x_coord = 30_314.7936
      # SVY21 Y coordinate
      y_coord = 31_490.4942

      # Call the conversion function directly
      {latitude, longitude} = CarParkLocationCache.convert_svy21_to_wgs84(x_coord, y_coord)

      # Verify the result is valid
      assert is_float(latitude)
      assert is_float(longitude)
      assert latitude >= -90 and latitude <= 90
      assert longitude >= -180 and longitude <= 180

      # Verify coordinates are within Singapore bounds
      assert latitude >= 1.0 and latitude <= 2.0
      assert longitude >= 103.0 and longitude <= 105.0

      # The converted coordinates should be reasonable for Singapore
      assert latitude > 1.0 and latitude < 2.0
      assert longitude > 103.0 and longitude < 105.0
    end

    test "handles edge cases in coordinate conversion" do
      # Test with zero coordinates
      {lat1, lon1} = CarParkLocationCache.convert_svy21_to_wgs84(0.0, 0.0)
      assert is_float(lat1)
      assert is_float(lon1)

      # Test with negative coordinates
      {lat2, lon2} = CarParkLocationCache.convert_svy21_to_wgs84(-1000.0, -1000.0)
      assert is_float(lat2)
      assert is_float(lon2)
    end
  end

  # Test the parsing functions
  describe "parsing functions" do
    test "parse_float handles valid and invalid inputs" do
      # Test with valid float string
      assert CarParkLocationCache.parse_float("123.45") == 123.45
      assert CarParkLocationCache.parse_float("0.0") == 0.0

      # Test with invalid inputs
      assert CarParkLocationCache.parse_float("invalid") == nil
      assert CarParkLocationCache.parse_float(nil) == nil
      assert CarParkLocationCache.parse_float("") == nil
    end

    test "parse_integer handles valid and invalid inputs" do
      # Test with valid integer string
      assert CarParkLocationCache.parse_integer("123") == 123
      assert CarParkLocationCache.parse_integer("0") == 0

      # Test with invalid inputs
      assert CarParkLocationCache.parse_integer("invalid") == 0
      assert CarParkLocationCache.parse_integer(nil) == 0
      assert CarParkLocationCache.parse_integer("") == 0
    end
  end

  # Test the validation function
  describe "validation" do
    test "valid_location? correctly validates location data" do
      # Valid location
      valid_location = %{
        carpark_number: "A1",
        address: "Test Address",
        latitude: 1.3521,
        longitude: 103.8198
      }

      assert CarParkLocationCache.valid_location?(valid_location) == true

      # Invalid locations
      assert CarParkLocationCache.valid_location?(%{valid_location | latitude: nil}) == false
      assert CarParkLocationCache.valid_location?(%{valid_location | longitude: nil}) == false

      assert CarParkLocationCache.valid_location?(%{valid_location | carpark_number: nil}) ==
               false

      assert CarParkLocationCache.valid_location?(%{valid_location | address: nil}) == false

      # Invalid coordinates
      assert CarParkLocationCache.valid_location?(%{valid_location | latitude: 91.0}) == false
      assert CarParkLocationCache.valid_location?(%{valid_location | latitude: -91.0}) == false
      assert CarParkLocationCache.valid_location?(%{valid_location | longitude: 181.0}) == false
      assert CarParkLocationCache.valid_location?(%{valid_location | longitude: -181.0}) == false
    end
  end
end

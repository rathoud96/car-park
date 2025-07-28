defmodule CarPark.Services.CarParkLocationService do
  @moduledoc """
  Service module for calculating distances and finding nearest car parks.
  """

  @data_folder "data"

  @type car_park_location :: %{
          carpark_number: String.t(),
          address: String.t(),
          latitude: float(),
          longitude: float(),
          car_park_type: String.t(),
          type_of_parking_system: String.t(),
          short_term_parking: String.t(),
          free_parking: String.t(),
          night_parking: String.t(),
          car_park_decks: integer(),
          gantry_height: float(),
          car_park_basement: String.t()
        }

  @type nearest_car_park_response :: %{
          address: String.t(),
          latitude: float(),
          longitude: float(),
          total_lots: integer(),
          available_lots: integer(),
          distance: float()
        }

  @type paginated_response :: %{
          data: [nearest_car_park_response()],
          total_count: integer(),
          page: integer(),
          per_page: integer(),
          total_pages: integer()
        }

  @doc """
  Loads all car park locations from the CSV file.

  ## Examples

      iex> load_car_park_locations()
      [%{carpark_number: "A1", address: "BLK 215 ANG MO KIO STREET 22", ...}, ...]
  """
  @spec load_car_park_locations() :: [car_park_location()]
  def load_car_park_locations do
    csv_file_path = find_csv_file()

    csv_file_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.map(&parse_car_park_location/1)
    |> Enum.filter(&valid_location?/1)
  end

  @doc """
  Finds the nearest car parks to a given location with pagination metadata.

  ## Examples

      iex> find_nearest_car_parks(1.37326, 103.897, 1, 3)
      %{data: [%{address: "BLK 401-413, 460-463 HOUGANG AVENUE 10", ...}], total_count: 50, page: 1, per_page: 3, total_pages: 17}
  """
  @spec find_nearest_car_parks(float(), float(), integer(), integer()) :: paginated_response()
  def find_nearest_car_parks(latitude, longitude, page, per_page) do
    locations = load_car_park_locations()

    # Extract carpark numbers for bulk query
    carpark_numbers = Enum.map(locations, & &1.carpark_number)

    # Get all car park data in a single query
    car_park_data_map = CarPark.CarParkDataContext.get_latest_car_park_data_bulk(carpark_numbers)

    # Process all locations with available slots
    all_available_car_parks =
      locations
      |> Enum.map(&add_distance_to_location(&1, latitude, longitude))
      |> Enum.sort_by(& &1.distance)
      |> Enum.map(&format_car_park_response_with_data(&1, car_park_data_map))
      |> Enum.filter(&has_available_slots?/1)

    # Calculate pagination metadata
    total_count = length(all_available_car_parks)
    total_pages = ceil(total_count / per_page)

    # Get paginated results
    paginated_data = paginate_results(all_available_car_parks, page, per_page)

    %{
      data: paginated_data,
      total_count: total_count,
      page: page,
      per_page: per_page,
      total_pages: total_pages
    }
  end

  @doc """
  Calculates the distance between two points using the Haversine formula.

  ## Examples

      iex> calculate_distance(1.37326, 103.897, 1.37429, 103.896)
      0.123
  """
  @spec calculate_distance(float(), float(), float(), float()) :: float()
  def calculate_distance(lat1, lon1, lat2, lon2) do
    # Convert degrees to radians
    lat1_rad = lat1 * :math.pi() / 180
    lon1_rad = lon1 * :math.pi() / 180
    lat2_rad = lat2 * :math.pi() / 180
    lon2_rad = lon2 * :math.pi() / 180

    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) * :math.pow(:math.sin(dlon / 2), 2)

    c = 2 * :math.asin(:math.sqrt(a))

    # Earth's radius in kilometers
    r = 6371

    r * c
  end

  # Private functions

  defp parse_car_park_location(row) do
    # Convert SVY21 coordinates to WGS84 (latitude/longitude)
    {latitude, longitude} =
      convert_svy21_to_wgs84(
        parse_float(row["x_coord"]),
        parse_float(row["y_coord"])
      )

    %{
      carpark_number: row["car_park_no"],
      address: row["address"],
      latitude: latitude,
      longitude: longitude,
      car_park_type: row["car_park_type"],
      type_of_parking_system: row["type_of_parking_system"],
      short_term_parking: row["short_term_parking"],
      free_parking: row["free_parking"],
      night_parking: row["night_parking"],
      car_park_decks: parse_integer(row["car_park_decks"]),
      gantry_height: parse_float(row["gantry_height"]),
      car_park_basement: row["car_park_basement"]
    }
  end

  defp convert_svy21_to_wgs84(x_coord, y_coord) do
    # This is a simplified conversion - in production you'd want a more accurate conversion
    # For now, we'll use a rough approximation based on Singapore's coordinate system
    # SVY21 to WGS84 conversion for Singapore
    # This is a simplified version - actual conversion would be more complex

    # Approximate conversion factors for Singapore
    # These are rough estimates and should be replaced with proper conversion
    latitude = 1.3521 + (y_coord - 30_000) / 1_000_000
    longitude = 103.8198 + (x_coord - 20_000) / 1_000_000

    {latitude, longitude}
  end

  defp valid_location?(location) do
    location.latitude != nil and
      location.longitude != nil and
      location.carpark_number != nil and
      location.address != nil
  end

  defp add_distance_to_location(location, target_lat, target_lon) do
    distance = calculate_distance(target_lat, target_lon, location.latitude, location.longitude)
    Map.put(location, :distance, distance)
  end

  defp paginate_results(results, page, per_page) do
    offset = (page - 1) * per_page

    results
    |> Enum.slice(offset, per_page)
  end

  defp format_car_park_response_with_data(location, car_park_data_map) do
    # Get the latest car park data from the pre-loaded map
    latest_data =
      Map.get(car_park_data_map, location.carpark_number, %CarPark.CarParkData{
        total_lots: 0,
        available_lots: 0
      })

    %{
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
      total_lots: latest_data.total_lots,
      available_lots: latest_data.available_lots
    }
  end

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
  end

  defp parse_float(_), do: nil

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp parse_integer(_), do: 0

  defp find_csv_file do
    case File.ls(@data_folder) do
      {:ok, files} ->
        csv_files = Enum.filter(files, &String.ends_with?(&1, ".csv"))

        case csv_files do
          [csv_file | _] -> Path.join(@data_folder, csv_file)
          [] -> raise "No CSV files found in #{@data_folder} directory"
        end

      {:error, reason} ->
        raise "Cannot read #{@data_folder} directory: #{inspect(reason)}"
    end
  end

  defp has_available_slots?(car_park) do
    car_park.available_lots > 0
  end
end

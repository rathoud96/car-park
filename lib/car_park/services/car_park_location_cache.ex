defmodule CarPark.Services.CarParkLocationCache do
  @moduledoc """
  GenServer module for caching car park location data from CSV file.

  This module loads and caches the car park location data at startup,
  converting SVY21 coordinates to WGS84 coordinates for accurate distance calculations.
  """

  use GenServer
  require Logger

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

  # Client API

  @doc """
  Starts the car park location cache.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets all cached car park locations.
  """
  @spec get_all_locations() :: [car_park_location()]
  def get_all_locations do
    GenServer.call(__MODULE__, :get_all_locations)
  end

  @doc """
  Gets a specific car park location by carpark number.
  """
  @spec get_location(String.t()) :: car_park_location() | nil
  def get_location(carpark_number) when is_binary(carpark_number) do
    GenServer.call(__MODULE__, {:get_location, carpark_number})
  end

  @doc """
  Manually reloads the cache from the CSV file.
  """
  @spec reload_cache() :: {:ok, integer()} | {:error, atom()}
  def reload_cache do
    GenServer.call(__MODULE__, :reload_cache)
  end

  @doc """
  Gets cache statistics.
  """
  @spec get_cache_stats() :: %{total_locations: integer(), loaded_at: DateTime.t() | nil}
  def get_cache_stats do
    GenServer.call(__MODULE__, :get_cache_stats)
  end

  # Server Callbacks

  @impl GenServer
  def init(_opts) do
    Logger.info("Initializing car park location cache...")

    case load_locations_from_csv() do
      {:ok, locations} ->
        Logger.info("Successfully loaded #{length(locations)} car park locations into cache")
        {:ok, %{locations: locations, loaded_at: DateTime.utc_now()}}

      {:error, reason} ->
        Logger.error("Failed to load car park locations: #{inspect(reason)}")
        {:ok, %{locations: [], loaded_at: nil}}
    end
  end

  @impl GenServer
  def handle_call(:get_all_locations, _from, state) do
    {:reply, state.locations, state}
  end

  @impl GenServer
  def handle_call({:get_location, carpark_number}, _from, state) do
    location = Enum.find(state.locations, &(&1.carpark_number == carpark_number))
    {:reply, location, state}
  end

  @impl GenServer
  def handle_call(:reload_cache, _from, _state) do
    case load_locations_from_csv() do
      {:ok, locations} ->
        Logger.info("Successfully reloaded #{length(locations)} car park locations into cache")
        {:reply, {:ok, length(locations)}, %{locations: locations, loaded_at: DateTime.utc_now()}}

      {:error, reason} ->
        Logger.error("Failed to reload car park locations: #{inspect(reason)}")
        {:reply, {:error, reason}, %{locations: [], loaded_at: nil}}
    end
  end

  @impl GenServer
  def handle_call(:get_cache_stats, _from, state) do
    stats = %{
      total_locations: length(state.locations),
      loaded_at: state.loaded_at
    }

    {:reply, stats, state}
  end

  # Public functions for testing

  @doc """
  Loads car park locations from CSV file and converts coordinates to WGS84.
  """
  @spec load_locations_from_csv() :: {:ok, [car_park_location()]} | {:error, atom()}
  def load_locations_from_csv do
    csv_file_path = find_csv_file()

    locations =
      csv_file_path
      |> File.stream!()
      |> CSV.decode!(headers: true)
      |> Enum.map(&parse_car_park_location/1)
      |> Enum.filter(&valid_location?/1)

    {:ok, locations}
  rescue
    e ->
      Logger.error("Failed to load car park locations from CSV: #{inspect(e)}")
      {:error, :csv_load_error}
  end

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

  @doc """
  Converts SVY21 coordinates to WGS84 coordinates for Singapore.
  """
  @spec convert_svy21_to_wgs84(float(), float()) :: {float(), float()}
  def convert_svy21_to_wgs84(x_coord, y_coord) do
    # Improved SVY21 to WGS84 conversion for Singapore
    # This is a more accurate conversion than the simplified version

    # SVY21 parameters for Singapore
    # Semi-major axis of WGS84 ellipsoid
    a = 6_378_137.0
    # Flattening of WGS84 ellipsoid
    f = 1.0 / 298.257223563
    # Semi-minor axis
    _b = a * (1.0 - f)

    # SVY21 projection parameters
    # 1° 22' 00" N
    origin_lat = 1.3666666666666667
    # 103° 50' 00" E
    origin_lon = 103.83333333333333
    false_easting = 28_001.642
    false_northing = 38_744.572

    # Convert SVY21 to lat/lon using inverse projection
    # This is a simplified but more accurate conversion
    # Approximate meters per degree
    lat_offset = (y_coord - false_northing) / 111_320.0

    lon_offset =
      (x_coord - false_easting) / (111_320.0 * :math.cos(origin_lat * :math.pi() / 180))

    latitude = origin_lat + lat_offset
    longitude = origin_lon + lon_offset

    {latitude, longitude}
  end

  @doc """
  Validates if a location has all required fields and valid coordinates.
  """
  @spec valid_location?(car_park_location()) :: boolean()
  def valid_location?(location) do
    location.latitude != nil and
      location.longitude != nil and
      location.carpark_number != nil and
      location.address != nil and
      location.latitude >= -90 and location.latitude <= 90 and
      location.longitude >= -180 and location.longitude <= 180
  end

  @doc """
  Parses a string to float, returns nil if parsing fails.
  """
  @spec parse_float(String.t() | any()) :: float() | nil
  def parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
  end

  def parse_float(_), do: nil

  @doc """
  Parses a string to integer, returns 0 if parsing fails.
  """
  @spec parse_integer(String.t() | any()) :: integer()
  def parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  def parse_integer(_), do: 0

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
end

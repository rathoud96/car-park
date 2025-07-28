defmodule CarPark.ExternalServices.CarParkApiService do
  @moduledoc """
  External service module for fetching car park availability data from the Singapore API.

  This module handles HTTP requests to external APIs and processes the responses.
  """

  @behaviour CarPark.ExternalServices.CarParkApiBehaviour

  require Logger

  alias CarPark.Repo

  @http_client Finch

  @type api_response :: %{
          items: [
            %{
              timestamp: String.t(),
              carpark_data: [
                %{
                  carpark_info: [
                    %{
                      total_lots: String.t(),
                      lot_type: String.t(),
                      lots_available: String.t()
                    }
                  ],
                  carpark_number: String.t(),
                  update_datetime: String.t()
                }
              ]
            }
          ]
        }

  @doc """
  Fetches car park availability data from the Singapore API and saves it to the database.
  """
  @spec fetch_and_save_car_park_data() :: {:ok, integer()} | {:error, atom()}
  def fetch_and_save_car_park_data do
    fetch_and_save_car_park_data(@http_client)
  end

  @spec fetch_and_save_car_park_data(module()) :: {:ok, integer()} | {:error, atom()}
  def fetch_and_save_car_park_data(http_client) do
    with {:ok, response} <- fetch_api_data(http_client),
         {:ok, parsed_data} <- parse_api_response(response),
         {:ok, saved_count} <- save_car_park_data(parsed_data) do
      Logger.info("Successfully saved #{saved_count} car park records")
      {:ok, saved_count}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch and save car park data: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches raw data from the Singapore car park availability API.

  ## Examples

      iex> fetch_api_data()
      {:ok, %{items: [...]}}

      iex> fetch_api_data()
      {:error, :network_error}
  """
  @spec fetch_api_data() :: {:ok, api_response()} | {:error, atom()}
  def fetch_api_data do
    fetch_api_data(@http_client)
  end

  @doc """
  Fetches raw data using the specified HTTP client.
  This function is primarily used for testing.
  """
  @spec fetch_api_data(module()) :: {:ok, api_response()} | {:error, atom()}
  def fetch_api_data(http_client) do
    fetch_api_data(http_client, Application.get_env(:car_park, :env, :dev) == :test)
  end

  @spec fetch_api_data(module(), boolean()) :: {:ok, api_response()} | {:error, atom()}
  def fetch_api_data(http_client, test_mode) do
    api_url = Application.get_env(:car_park, :external_apis)[:car_park_availability_url]

    case http_client.build(:get, api_url, [{"Content-Type", "application/json"}])
         |> http_client.request(CarPark.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, _reason} -> {:error, :invalid_json}
        end

      {:ok, %Finch.Response{status: status}} ->
        log_level = if test_mode, do: :debug, else: :error
        Logger.log(log_level, "API request failed with status: #{status}")
        {:error, :api_error}

      {:error, reason} ->
        log_level = if test_mode, do: :debug, else: :error
        Logger.log(log_level, "Network error: #{inspect(reason)}")
        {:error, :network_error}
    end
  end

  @doc """
  Parses the API response to extract car park data.

  ## Examples

      iex> parse_api_response(%{items: [%{carpark_data: [...]}]})
      {:ok, [%{carpark_number: "A1", total_lots: 100, ...}]}

      iex> parse_api_response(%{})
      {:error, :invalid_response_format}
  """
  @spec parse_api_response(api_response()) :: {:ok, [map()]} | {:error, atom()}
  def parse_api_response(%{"items" => [%{"carpark_data" => carpark_data} | _]}) do
    parsed_data =
      carpark_data
      |> Enum.flat_map(fn carpark ->
        carpark_number = carpark["carpark_number"]
        update_datetime = parse_datetime(carpark["update_datetime"])

        carpark["carpark_info"]
        |> Enum.map(fn info ->
          %{
            carpark_number: carpark_number,
            total_lots: String.to_integer(info["total_lots"]),
            available_lots: String.to_integer(info["lots_available"]),
            update_datetime: update_datetime
          }
        end)
      end)

    {:ok, parsed_data}
  end

  def parse_api_response(_), do: {:error, :invalid_response_format}

  @doc """
  Saves car park data to the database using bulk insert.
  """
  @spec save_car_park_data([map()]) :: {:ok, integer()} | {:error, atom()}
  def save_car_park_data(car_park_data_list) when is_list(car_park_data_list) do
    save_car_park_data(car_park_data_list, Application.get_env(:car_park, :env, :dev) == :test)
  end

  @spec save_car_park_data([map()], boolean()) :: {:ok, integer()} | {:error, atom()}
  def save_car_park_data(car_park_data_list, test_mode) when is_list(car_park_data_list) do
    if Enum.empty?(car_park_data_list) do
      {:ok, 0}
    else
      # Prepare data for bulk insert
      now = DateTime.utc_now()

      records_to_insert =
        Enum.map(car_park_data_list, fn data ->
          %{
            carpark_number: data.carpark_number,
            total_lots: data.total_lots,
            available_lots: data.available_lots,
            update_datetime: data.update_datetime,
            inserted_at: now,
            updated_at: now
          }
        end)

      try do
        {count, _} = Repo.insert_all("car_park_data", records_to_insert)
        Logger.info("Successfully bulk inserted #{count} car park records")
        {:ok, count}
      rescue
        e ->
          log_level = if test_mode, do: :debug, else: :error
          Logger.log(log_level, "Failed to bulk insert car park data: #{inspect(e)}")
          {:error, :bulk_insert_error}
      end
    end
  end

  @doc """
  Parses datetime string from the API response.

  ## Examples

      iex> parse_datetime("2025-07-28T07:25:17")
      ~U[2025-07-28 07:25:17Z]

      iex> parse_datetime("invalid")
      ~U[2025-01-01 00:00:00Z]
  """
  @spec parse_datetime(String.t()) :: DateTime.t()
  def parse_datetime(datetime_string) when is_binary(datetime_string) do
    parse_datetime(datetime_string, Application.get_env(:car_park, :env, :dev) == :test)
  end

  def parse_datetime(_),
    do: parse_datetime("invalid", Application.get_env(:car_park, :env, :dev) == :test)

  @spec parse_datetime(String.t(), boolean()) :: DateTime.t()
  def parse_datetime(datetime_string, test_mode) when is_binary(datetime_string) do
    # Try parsing as ISO8601 first
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> handle_datetime_parse_error(datetime_string, test_mode)
    end
  end

  def parse_datetime(_, test_mode), do: parse_datetime("invalid", test_mode)

  defp handle_datetime_parse_error(datetime_string, test_mode) do
    # Try parsing as a simpler format (YYYY-MM-DDTHH:MM:SS)
    case parse_simple_datetime(datetime_string) do
      {:ok, datetime} ->
        datetime

      {:error, _reason} ->
        log_level = if test_mode, do: :debug, else: :warning
        Logger.log(log_level, "Failed to parse datetime: #{datetime_string}, using default")
        ~U[2025-01-01 00:00:00Z]
    end
  end

  @doc """
  Parses a simple datetime format (YYYY-MM-DDTHH:MM:SS).
  """
  @spec parse_simple_datetime(String.t()) :: {:ok, DateTime.t()} | {:error, atom()}
  def parse_simple_datetime(datetime_string) do
    case Regex.run(~r/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/, datetime_string) do
      [_, year, month, day, hour, minute, second] ->
        try do
          datetime = %DateTime{
            year: String.to_integer(year),
            month: String.to_integer(month),
            day: String.to_integer(day),
            hour: String.to_integer(hour),
            minute: String.to_integer(minute),
            second: String.to_integer(second),
            microsecond: {0, 6},
            time_zone: "Etc/UTC",
            zone_abbr: "UTC",
            utc_offset: 0,
            std_offset: 0
          }

          {:ok, datetime}
        rescue
          _ -> {:error, :invalid_datetime}
        end

      _ ->
        {:error, :invalid_format}
    end
  end
end

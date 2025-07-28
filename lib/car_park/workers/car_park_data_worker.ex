defmodule CarPark.Workers.CarParkDataWorker do
  @moduledoc """
  Worker module for fetching and updating car park data at application start.

  This module is responsible for:
  - Fetching car park data from external API
  - Upserting data to update existing records
  - Running once at application start
  """

  use GenServer
  require Logger

  alias CarPark.Repo

  # Get the API service from configuration (allows mocking in tests)
  # Use runtime configuration instead of compile-time for better test flexibility
  defp api_service do
    Application.get_env(
      :car_park,
      :car_park_api_service,
      CarPark.ExternalServices.CarParkApiService
    )
  end

  @type t :: %__MODULE__{
          loaded: boolean()
        }

  defstruct [:loaded]

  @doc """
  Starts the car park data worker.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually triggers a car park data fetch.
  """
  @spec fetch_data() :: {:ok, integer()} | {:error, atom()}
  def fetch_data do
    GenServer.call(__MODULE__, :fetch_data)
  end

  @impl GenServer
  def init(_opts) do
    # Fetch data immediately on start
    Process.send_after(self(), :fetch_data, 1000)

    {:ok, %__MODULE__{loaded: false}}
  end

  @impl GenServer
  def handle_info(:fetch_data, state) do
    Logger.info("Starting car park data fetch...")

    case fetch_and_upsert_data() do
      {:ok, count} ->
        Logger.info("Successfully loaded #{count} car park records at startup")
        {:noreply, %{state | loaded: true}}

      {:error, reason} ->
        Logger.error("Failed to fetch car park data at startup: #{inspect(reason)}")
        {:noreply, %{state | loaded: false}}
    end
  end

  @impl GenServer
  def handle_call(:fetch_data, _from, state) do
    result = fetch_and_upsert_data()
    {:reply, result, state}
  end

  @doc """
  Fetches car park data from API and upserts it to the database.
  """
  @spec fetch_and_upsert_data() :: {:ok, integer()} | {:error, atom()}
  def fetch_and_upsert_data do
    with {:ok, response} <- api_service().fetch_api_data(),
         {:ok, parsed_data} <- api_service().parse_api_response(response),
         {:ok, upserted_count} <- upsert_car_park_data(parsed_data) do
      {:ok, upserted_count}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch and upsert car park data: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Upserts car park data to the database using bulk insert with conflict resolution.
  """
  @spec upsert_car_park_data([map()]) :: {:ok, integer()} | {:error, atom()}
  def upsert_car_park_data(car_park_data_list) when is_list(car_park_data_list) do
    if Enum.empty?(car_park_data_list) do
      {:ok, 0}
    else
      try do
        # Deduplicate data based on carpark_number and update_datetime
        # Keep the last occurrence of each unique combination
        deduplicated_data =
          car_park_data_list
          |> Enum.reverse()
          |> Enum.uniq_by(fn data -> {data.carpark_number, data.update_datetime} end)
          |> Enum.reverse()

        # Prepare data for bulk insert
        now = DateTime.utc_now()

        records_to_insert =
          Enum.map(deduplicated_data, fn data ->
            %{
              carpark_number: data.carpark_number,
              total_lots: data.total_lots,
              available_lots: data.available_lots,
              update_datetime: data.update_datetime,
              inserted_at: now,
              updated_at: now
            }
          end)

        # Use bulk insert with ON CONFLICT for efficient upserts
        {count, _} =
          Repo.insert_all("car_park_data", records_to_insert,
            on_conflict: {:replace, [:total_lots, :available_lots, :updated_at]},
            conflict_target: [:carpark_number, :update_datetime]
          )

        Logger.info(
          "Successfully bulk upserted #{count} car park records (deduplicated from #{length(car_park_data_list)} input records)"
        )

        {:ok, count}
      rescue
        e ->
          Logger.error("Failed to bulk upsert car park data: #{inspect(e)}")
          {:error, :bulk_upsert_error}
      end
    end
  end
end

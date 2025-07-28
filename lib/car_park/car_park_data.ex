defmodule CarPark.CarParkDataContext do
  @moduledoc """
  Context module for car park data operations.

  This module contains all business logic related to car park data including
  creation, retrieval, and data validation operations.
  """

  import Ecto.Query
  alias CarPark.CarParkData
  alias CarPark.Repo

  @type car_park_data_attrs :: %{
          total_lots: integer(),
          available_lots: integer(),
          carpark_number: String.t(),
          update_datetime: DateTime.t()
        }

  @doc """
  Creates a new car park data record.

  ## Examples

      iex> create_car_park_data(%{total_lots: 100, available_lots: 50, carpark_number: "A1", update_datetime: ~U[2024-01-01 12:00:00Z]})
      {:ok, %CarParkData{}}

      iex> create_car_park_data(%{total_lots: -1})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_car_park_data(car_park_data_attrs()) ::
          {:ok, CarParkData.t()} | {:error, Ecto.Changeset.t()}
  def create_car_park_data(attrs) do
    %CarParkData{}
    |> CarParkData.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves a car park data record by ID.

  ## Examples

      iex> get_car_park_data(1)
      {:ok, %CarParkData{}}

      iex> get_car_park_data(999)
      {:error, :not_found}
  """
  @spec get_car_park_data(integer()) :: {:ok, CarParkData.t()} | {:error, :not_found}
  def get_car_park_data(id) when is_integer(id) do
    case Repo.get(CarParkData, id) do
      nil -> {:error, :not_found}
      car_park_data -> {:ok, car_park_data}
    end
  end

  @doc """
  Lists all car park data records.

  ## Examples

      iex> list_car_park_data()
      [%CarParkData{}, ...]
  """
  @spec list_car_park_data() :: [CarParkData.t()]
  def list_car_park_data do
    CarParkData
    |> order_by([c], desc: c.update_datetime)
    |> Repo.all()
  end

  @doc """
  Lists car park data records by carpark number.

  ## Examples

      iex> list_car_park_data_by_number("A1")
      [%CarParkData{}, ...]
  """
  @spec list_car_park_data_by_number(String.t()) :: [CarParkData.t()]
  def list_car_park_data_by_number(carpark_number) when is_binary(carpark_number) do
    CarParkData
    |> where([c], c.carpark_number == ^carpark_number)
    |> order_by([c], desc: c.update_datetime)
    |> Repo.all()
  end

  @doc """
  Gets the latest car park data for a specific carpark number.

  ## Examples

      iex> get_latest_car_park_data("A1")
      {:ok, %CarParkData{}}

      iex> get_latest_car_park_data("NONEXISTENT")
      {:error, :not_found}
  """
  @spec get_latest_car_park_data(String.t()) :: {:ok, CarParkData.t()} | {:error, :not_found}
  def get_latest_car_park_data(carpark_number) when is_binary(carpark_number) do
    case CarParkData
         |> where([c], c.carpark_number == ^carpark_number)
         |> order_by([c], desc: c.update_datetime)
         |> limit(1)
         |> Repo.one() do
      nil -> {:error, :not_found}
      car_park_data -> {:ok, car_park_data}
    end
  end

  @doc """
  Updates a car park data record.

  ## Examples

      iex> update_car_park_data(car_park_data, %{available_lots: 25})
      {:ok, %CarParkData{}}

      iex> update_car_park_data(car_park_data, %{available_lots: -1})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_car_park_data(CarParkData.t(), map()) ::
          {:ok, CarParkData.t()} | {:error, Ecto.Changeset.t()}
  def update_car_park_data(%CarParkData{} = car_park_data, attrs) do
    car_park_data
    |> CarParkData.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a car park data record.

  ## Examples

      iex> delete_car_park_data(car_park_data)
      {:ok, %CarParkData{}}
  """
  @spec delete_car_park_data(CarParkData.t()) ::
          {:ok, CarParkData.t()} | {:error, Ecto.Changeset.t()}
  def delete_car_park_data(%CarParkData{} = car_park_data) do
    Repo.delete(car_park_data)
  end

  @doc """
  Deletes all car park data records.
  This function is primarily used for testing purposes.

  ## Examples

      iex> delete_all_car_park_data()
      {:ok, 5}
  """
  @spec delete_all_car_park_data() :: {:ok, integer()}
  def delete_all_car_park_data do
    {count, _} = Repo.delete_all(CarParkData)
    {:ok, count}
  end

  @doc """
  Gets car park data within a date range.

  ## Examples

      iex> get_car_park_data_in_range("A1", ~U[2024-01-01 00:00:00Z], ~U[2024-01-02 00:00:00Z])
      [%CarParkData{}, ...]
  """
  @spec get_car_park_data_in_range(String.t(), DateTime.t(), DateTime.t()) :: [CarParkData.t()]
  def get_car_park_data_in_range(carpark_number, start_datetime, end_datetime)
      when is_binary(carpark_number) and is_struct(start_datetime, DateTime) and
             is_struct(end_datetime, DateTime) do
    CarParkData
    |> where([c], c.carpark_number == ^carpark_number)
    |> where([c], c.update_datetime >= ^start_datetime and c.update_datetime <= ^end_datetime)
    |> order_by([c], asc: c.update_datetime)
    |> Repo.all()
  end

  @doc """
  Gets the latest car park data for multiple carpark numbers in a single query.
  This is optimized to prevent N+1 queries.

  ## Examples

      iex> get_latest_car_park_data_bulk(["A1", "A2", "A3"])
      %{"A1" => %CarParkData{}, "A2" => %CarParkData{}, "A3" => %CarParkData{}}

      iex> get_latest_car_park_data_bulk([])
      %{}
  """
  @spec get_latest_car_park_data_bulk([String.t()]) :: %{String.t() => CarParkData.t()}
  def get_latest_car_park_data_bulk(carpark_numbers) when is_list(carpark_numbers) do
    if Enum.empty?(carpark_numbers) do
      %{}
    else
      # Use a window function to get the latest record for each carpark_number
      query = """
      SELECT DISTINCT ON (carpark_number)
        id, total_lots, available_lots, carpark_number, update_datetime, inserted_at, updated_at
      FROM car_park_data
      WHERE carpark_number = ANY($1)
      ORDER BY carpark_number, update_datetime DESC
      """

      case Repo.query(query, [carpark_numbers]) do
        {:ok, %{rows: rows}} ->
          convert_rows_to_map(rows)

        {:error, _reason} ->
          # Fallback to empty map if query fails
          %{}
      end
    end
  end

  defp convert_rows_to_map(rows) do
    rows
    |> Enum.map(fn row ->
      [id, total_lots, available_lots, carpark_number, update_datetime, inserted_at, updated_at] =
        row

      %CarParkData{
        id: id,
        total_lots: total_lots,
        available_lots: available_lots,
        carpark_number: carpark_number,
        update_datetime: update_datetime,
        inserted_at: inserted_at,
        updated_at: updated_at
      }
    end)
    |> Enum.map(fn data -> {data.carpark_number, data} end)
    |> Map.new()
  end
end

defmodule CarPark.Factory do
  @moduledoc """
  Factory module for generating test data using ExMachina.
  """

  use ExMachina.Ecto, repo: CarPark.Repo

  alias CarPark.CarParkData

  @doc """
  Factory for creating car park data records.
  """
  def car_park_data_factory do
    total_lots = Enum.random(50..500)
    available_lots = Enum.random(0..total_lots)

    %CarParkData{
      carpark_number: sequence(:carpark_number, &"A#{&1}"),
      total_lots: total_lots,
      available_lots: available_lots,
      update_datetime: DateTime.utc_now()
    }
  end

  @doc """
  Creates a car park data record with specific attributes.
  """
  def car_park_data_with_attrs(attrs \\ %{}) do
    car_park_data_factory()
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  @doc """
  Creates a list of car park data records.
  """
  def car_park_data_list(count \\ 3, attrs \\ %{}) do
    for _ <- 1..count do
      car_park_data_with_attrs(attrs)
    end
  end
end

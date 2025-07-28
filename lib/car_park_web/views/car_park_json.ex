defmodule CarParkWeb.CarParkJSON do
  @moduledoc """
  JSON views for car park data responses.
  """

  @doc """
  Renders a list of nearest car parks with pagination metadata.
  """
  def nearest(%{
        data: data,
        total_count: total_count,
        page: page,
        per_page: per_page,
        total_pages: total_pages
      }) do
    %{
      data: for(car_park <- data, do: nearest_car_park(car_park)),
      pagination: %{
        total_count: total_count,
        page: page,
        per_page: per_page,
        total_pages: total_pages
      },
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Renders an error response.
  """
  def error(%{message: message}) do
    %{
      success: false,
      error: message,
      timestamp: DateTime.utc_now()
    }
  end

  defp nearest_car_park(car_park) do
    %{
      address: car_park.address,
      latitude: car_park.latitude,
      longitude: car_park.longitude,
      total_lots: car_park.total_lots,
      available_lots: car_park.available_lots
    }
  end
end

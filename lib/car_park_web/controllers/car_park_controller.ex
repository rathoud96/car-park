defmodule CarParkWeb.CarParkController do
  use CarParkWeb, :controller

  alias CarPark.Services.CarParkLocationService
  alias CarParkWeb.CarParkJSON

  @doc """
  Finds the nearest car parks to the given coordinates.
  Only returns car parks that have available parking slots.
  Includes pagination metadata for client-side pagination controls.

  ## Parameters

  - `latitude` (required): Latitude coordinate
  - `longitude` (required): Longitude coordinate
  - `page` (optional): Page number for pagination (default: 1)
  - `per_page` (optional): Number of results per page (default: 10)

  ## Response Format

  ```json
  {
    "data": [...],
    "pagination": {
      "total_count": 150,
      "page": 1,
      "per_page": 10,
      "total_pages": 15
    },
    "timestamp": "2025-07-28T14:47:17.219232Z"
  }
  ```

  ## Examples

      GET /carparks/nearest?latitude=1.3521&longitude=103.8198
      GET /carparks/nearest?latitude=1.3521&longitude=103.8198&page=2&per_page=5
  """
  @spec nearest(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def nearest(conn, params) do
    with {:ok, latitude} <- parse_float(params["latitude"]),
         {:ok, longitude} <- parse_float(params["longitude"]),
         {:ok, page} <- parse_integer_with_default(params["page"], 1),
         {:ok, per_page} <- parse_integer_with_default(params["per_page"], 10) do
      result = CarParkLocationService.find_nearest_car_parks(latitude, longitude, page, per_page)
      render(conn, :nearest, result)
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(CarParkJSON.error(%{message: "Invalid parameters: #{reason}"}))
    end
  end

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> {:ok, float}
      :error -> {:error, "Invalid float value"}
    end
  end

  defp parse_float(_), do: {:error, "Missing or invalid float value"}

  defp parse_integer_with_default(value, _default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} when int > 0 -> {:ok, int}
      _ -> {:error, "Invalid integer value"}
    end
  end

  defp parse_integer_with_default(_value, default), do: {:ok, default}
end

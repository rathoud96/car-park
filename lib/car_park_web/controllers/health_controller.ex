defmodule CarParkWeb.HealthController do
  use CarParkWeb, :controller

  @doc """
  Health check endpoint for Docker health checks.
  Returns a simple JSON response indicating the service is healthy.
  """
  def check(conn, _params) do
    json(conn, %{
      status: "healthy",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      service: "car_park"
    })
  end
end

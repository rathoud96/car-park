defmodule CarPark.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CarParkWeb.Telemetry,
      CarPark.Repo,
      {DNSCluster, query: Application.get_env(:car_park, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CarPark.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CarPark.Finch},
      # Start to serve requests, typically the last entry
      CarParkWeb.Endpoint
    ]

    # Add the car park data worker only in non-test environments
    children =
      if Application.get_env(:car_park, :env, :dev) != :test do
        children ++ [CarPark.Workers.CarParkDataWorker]
      else
        children
      end

    # Always start the location cache (needed for tests)
    children = children ++ [CarPark.Services.CarParkLocationCache]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CarPark.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CarParkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

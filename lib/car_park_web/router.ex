defmodule CarParkWeb.Router do
  use CarParkWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health check endpoint
  get "/health", CarParkWeb.HealthController, :check

  scope "/carparks", CarParkWeb do
    pipe_through :api

    # Nearest car parks endpoint
    get "/nearest", CarParkController, :nearest
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:car_park, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: CarParkWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

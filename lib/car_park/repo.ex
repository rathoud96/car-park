defmodule CarPark.Repo do
  use Ecto.Repo,
    otp_app: :car_park,
    adapter: Ecto.Adapters.Postgres
end

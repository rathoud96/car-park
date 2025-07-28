import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :car_park, CarPark.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "car_park_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :car_park, CarParkWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "nJDUXodqqXpWOJBsNcMyHbjrRtLsmfZSIY8YpR60zhVTFw9GnN7IojDyACl02pnN",
  server: false

# In test we don't send emails
config :car_park, CarPark.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure Mox for mocking in tests
config :car_park, :car_park_api_service, CarParkApiServiceMock

# Set environment to test for Dialyzer compatibility
config :car_park, :env, :test

# Configure Mox mocks
config :mox,
  mocks: [
    {CarParkApiServiceMock, CarPark.ExternalServices.CarParkApiBehaviour}
  ]

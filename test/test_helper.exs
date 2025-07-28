ExUnit.start()

# Configure Ecto sandbox for testing
Ecto.Adapters.SQL.Sandbox.mode(CarPark.Repo, :manual)

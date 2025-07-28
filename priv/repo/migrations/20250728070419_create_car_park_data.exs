defmodule CarPark.Repo.Migrations.CreateCarParkData do
  use Ecto.Migration

  def change do
    create table(:car_park_data) do
      add :total_lots, :integer, null: false
      add :available_lots, :integer, null: false
      add :carpark_number, :string, null: false
      add :update_datetime, :utc_datetime, null: false

      timestamps()
    end

    # Add index on carpark_number for efficient queries
    create index(:car_park_data, [:carpark_number])

    # Add index on update_datetime for time-based queries
    create index(:car_park_data, [:update_datetime])
  end
end

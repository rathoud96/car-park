defmodule CarPark.Repo.Migrations.AddUniqueConstraintToCarParkData do
  use Ecto.Migration

  def change do
    # Add unique constraint on carpark_number and update_datetime
    # This ensures we can properly upsert records based on these fields
    create unique_index(:car_park_data, [:carpark_number, :update_datetime],
             name: :car_park_data_carpark_number_update_datetime_index
           )
  end
end

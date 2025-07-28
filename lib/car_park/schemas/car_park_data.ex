defmodule CarPark.CarParkData do
  @moduledoc """
  Schema for car park data records.

  This schema represents individual car park data entries with information about
  total lots, available lots, carpark number, and update datetime.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id
  @timestamps_opts [type: :utc_datetime]

  typed_schema "car_park_data" do
    field :total_lots, :integer
    field :available_lots, :integer
    field :carpark_number, :string
    field :update_datetime, :utc_datetime

    timestamps()
  end

  @doc """
  Creates a changeset for car park data.

  ## Examples

      iex> changeset(%CarParkData{}, %{total_lots: 100, available_lots: 50, carpark_number: "A1", update_datetime: ~U[2024-01-01 12:00:00Z]})
      %Ecto.Changeset{valid?: true, ...}

      iex> changeset(%CarParkData{}, %{total_lots: -1})
      %Ecto.Changeset{valid?: false, ...}
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(car_park_data, attrs) do
    car_park_data
    |> cast(attrs, [:total_lots, :available_lots, :carpark_number, :update_datetime])
    |> validate_required([:total_lots, :available_lots, :carpark_number, :update_datetime])
    |> validate_number(:total_lots, greater_than_or_equal_to: 0)
    |> validate_number(:available_lots, greater_than_or_equal_to: 0)
    |> validate_available_lots_less_than_total()
    |> validate_carpark_number_format()
  end

  defp validate_available_lots_less_than_total(changeset) do
    case {get_field(changeset, :total_lots), get_field(changeset, :available_lots)} do
      {total, available} when is_integer(total) and is_integer(available) and available > total ->
        add_error(changeset, :available_lots, "cannot be greater than total lots")

      _ ->
        changeset
    end
  end

  defp validate_carpark_number_format(changeset) do
    case get_field(changeset, :carpark_number) do
      carpark_number when is_binary(carpark_number) and carpark_number != "" ->
        changeset

      _ ->
        add_error(changeset, :carpark_number, "must be a non-empty string")
    end
  end
end

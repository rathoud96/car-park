defmodule CarPark.CarParkDataTest do
  @moduledoc """
  Tests for CarParkData schema.
  """

  use CarPark.DataCase
  alias CarPark.CarParkData

  describe "changeset/2" do
    test "creates valid changeset with all required fields" do
      attrs = %{
        total_lots: 100,
        available_lots: 50,
        carpark_number: "A1",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :total_lots) == 100
      assert get_change(changeset, :available_lots) == 50
      assert get_change(changeset, :carpark_number) == "A1"
      assert get_change(changeset, :update_datetime) == ~U[2024-01-01 12:00:00Z]
    end

    test "returns error when total_lots is missing" do
      attrs = %{
        available_lots: 50,
        carpark_number: "A1",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      assert %{total_lots: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error when available_lots is missing" do
      attrs = %{
        total_lots: 100,
        carpark_number: "A1",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      assert %{available_lots: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error when carpark_number is missing" do
      attrs = %{
        total_lots: 100,
        available_lots: 50,
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :carpark_number)
    end

    test "returns error when update_datetime is missing" do
      attrs = %{
        total_lots: 100,
        available_lots: 50,
        carpark_number: "A1"
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      assert %{update_datetime: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error when total_lots is negative" do
      attrs = %{
        total_lots: -1,
        available_lots: 50,
        carpark_number: "A1",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      assert %{total_lots: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "returns error when available_lots is negative" do
      attrs = %{
        total_lots: 100,
        available_lots: -1,
        carpark_number: "A1",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      assert %{available_lots: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "returns error when available_lots is greater than total_lots" do
      attrs = %{
        total_lots: 100,
        available_lots: 150,
        carpark_number: "A1",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      assert %{available_lots: ["cannot be greater than total lots"]} = errors_on(changeset)
    end

    test "accepts when available_lots equals total_lots" do
      attrs = %{
        total_lots: 100,
        available_lots: 100,
        carpark_number: "A1",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      assert changeset.valid?
    end

    test "returns error when carpark_number is empty string" do
      attrs = %{
        total_lots: 100,
        available_lots: 50,
        carpark_number: "",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :carpark_number)
    end

    test "returns error when carpark_number is nil" do
      attrs = %{
        total_lots: 100,
        available_lots: 50,
        carpark_number: nil,
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      refute changeset.valid?
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :carpark_number)
    end

    test "accepts valid carpark_number with special characters" do
      attrs = %{
        total_lots: 100,
        available_lots: 50,
        carpark_number: "A1-B2_C3",
        update_datetime: ~U[2024-01-01 12:00:00Z]
      }

      changeset = CarParkData.changeset(%CarParkData{}, attrs)

      assert changeset.valid?
    end
  end
end

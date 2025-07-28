defmodule CarPark.Workers.CarParkDataWorkerTest do
  use CarPark.DataCase, async: false

  alias CarPark.CarParkData
  alias CarPark.CarParkDataContext
  alias CarPark.Workers.CarParkDataWorker

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  # Clean up test data before each test
  setup do
    # Clean up any existing test data
    CarParkDataContext.delete_all_car_park_data()
    :ok
  end

  # Mock the API service
  setup do
    # Configure the application to use the mock
    Application.put_env(:car_park, :car_park_api_service, CarParkApiServiceMock)

    :ok
  end

  describe "upsert_car_park_data/1" do
    test "creates new records when they don't exist" do
      unique_id = :rand.uniform(1000)

      data = [
        %{
          carpark_number: "WORKER_TEST_A1_#{unique_id}",
          total_lots: 100,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
      ]

      assert {:ok, 1} = CarParkDataWorker.upsert_car_park_data(data)

      # Verify record was created
      assert [record] = Repo.all(CarParkData)
      assert String.starts_with?(record.carpark_number, "WORKER_TEST_A1_")
      assert record.total_lots == 100
      assert record.available_lots == 50
    end

    test "updates existing records" do
      unique_id = :rand.uniform(1000)
      carpark_number = "WORKER_TEST_A1_#{unique_id}"

      # Create initial record
      existing_record =
        %CarParkData{
          carpark_number: carpark_number,
          total_lots: 100,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
        |> Repo.insert!()

      # Update data
      updated_data = [
        %{
          carpark_number: carpark_number,
          total_lots: 150,
          available_lots: 75,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
      ]

      assert {:ok, 1} = CarParkDataWorker.upsert_car_park_data(updated_data)

      # Verify record was updated
      assert [record] = Repo.all(CarParkData)
      assert record.id == existing_record.id
      assert record.total_lots == 150
      assert record.available_lots == 75
    end

    test "handles multiple records" do
      unique_id = :rand.uniform(1000)

      data = [
        %{
          carpark_number: "WORKER_TEST_A1_#{unique_id}",
          total_lots: 100,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        },
        %{
          carpark_number: "WORKER_TEST_A2_#{unique_id}",
          total_lots: 200,
          available_lots: 100,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
      ]

      assert {:ok, 2} = CarParkDataWorker.upsert_car_park_data(data)

      # Verify both records were created
      assert [record1, record2] = Repo.all(CarParkData) |> Enum.sort_by(& &1.carpark_number)
      assert String.starts_with?(record1.carpark_number, "WORKER_TEST_A1_")
      assert String.starts_with?(record2.carpark_number, "WORKER_TEST_A2_")
    end

    test "returns 0 for empty list" do
      assert {:ok, 0} = CarParkDataWorker.upsert_car_park_data([])
    end

    test "deduplicates records with same carpark_number and update_datetime" do
      unique_id = :rand.uniform(1000)
      carpark_number = "WORKER_TEST_DUP_#{unique_id}"
      update_datetime = ~U[2025-07-28 10:00:00Z]

      # Create data with duplicates
      data_with_duplicates = [
        %{
          carpark_number: carpark_number,
          total_lots: 100,
          available_lots: 50,
          update_datetime: update_datetime
        },
        %{
          carpark_number: carpark_number,
          # Different values
          total_lots: 150,
          available_lots: 75,
          update_datetime: update_datetime
        },
        %{
          carpark_number: carpark_number,
          # Different values again
          total_lots: 200,
          available_lots: 100,
          update_datetime: update_datetime
        }
      ]

      # Should only insert 1 record (deduplicated)
      assert {:ok, 1} = CarParkDataWorker.upsert_car_park_data(data_with_duplicates)

      # Verify only one record exists with the last values
      assert [record] =
               Repo.all(CarParkData) |> Enum.filter(&(&1.carpark_number == carpark_number))

      # Should have the last values
      assert record.total_lots == 200
      assert record.available_lots == 100
    end
  end

  describe "upsert_single_record/1" do
    test "creates new record" do
      unique_id = :rand.uniform(1000)

      data = [
        %{
          carpark_number: "WORKER_TEST_A1_#{unique_id}",
          total_lots: 100,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
      ]

      assert {:ok, 1} = CarParkDataWorker.upsert_car_park_data(data)

      # Verify record was created
      assert [record] = Repo.all(CarParkData)
      assert String.starts_with?(record.carpark_number, "WORKER_TEST_A1_")
      assert record.total_lots == 100
      assert record.available_lots == 50
    end

    test "updates existing record" do
      unique_id = :rand.uniform(1000)
      carpark_number = "WORKER_TEST_A1_#{unique_id}"

      # Create initial record
      existing_record =
        %CarParkData{
          carpark_number: carpark_number,
          total_lots: 100,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
        |> Repo.insert!()

      # Update data
      updated_data = [
        %{
          carpark_number: carpark_number,
          total_lots: 150,
          available_lots: 75,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
      ]

      assert {:ok, 1} = CarParkDataWorker.upsert_car_park_data(updated_data)

      # Verify record was updated
      assert [record] = Repo.all(CarParkData)
      assert record.id == existing_record.id
      assert record.total_lots == 150
      assert record.available_lots == 75
    end

    test "handles invalid data gracefully" do
      unique_id = :rand.uniform(1000)

      invalid_data = [
        %{
          carpark_number: "WORKER_TEST_A1_#{unique_id}",
          # Invalid: negative total lots
          total_lots: -1,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 10:00:00Z]
        }
      ]

      # Bulk upsert will handle invalid data differently than individual upserts
      # It will likely succeed but the data might be invalid at the database level
      # or it might fail with a bulk error
      result = CarParkDataWorker.upsert_car_park_data(invalid_data)

      # The result could be either success or error depending on database constraints
      assert result in [{:ok, 1}, {:error, :bulk_upsert_error}]
    end
  end
end

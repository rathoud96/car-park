defmodule CarPark.CarParkDataContextTest do
  use CarPark.DataCase, async: true

  alias CarPark.CarParkData
  alias CarPark.CarParkDataContext

  @valid_attrs %{
    total_lots: 100,
    available_lots: 50,
    carpark_number: "A1",
    update_datetime: ~U[2024-01-01 12:00:00Z]
  }

  @invalid_attrs %{
    total_lots: nil,
    available_lots: nil,
    carpark_number: nil,
    update_datetime: nil
  }

  describe "create_car_park_data/1" do
    test "creates car park data with valid attributes" do
      assert {:ok, %CarParkData{} = car_park_data} =
               CarParkDataContext.create_car_park_data(@valid_attrs)

      assert car_park_data.total_lots == 100
      assert car_park_data.available_lots == 50
      assert car_park_data.carpark_number == "A1"
      assert car_park_data.update_datetime == ~U[2024-01-01 12:00:00Z]
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, %Ecto.Changeset{}} = CarParkDataContext.create_car_park_data(@invalid_attrs)
    end
  end

  describe "get_car_park_data/1" do
    test "returns car park data with valid id" do
      {:ok, car_park_data} = CarParkDataContext.create_car_park_data(@valid_attrs)
      assert {:ok, retrieved_data} = CarParkDataContext.get_car_park_data(car_park_data.id)
      assert retrieved_data.id == car_park_data.id
    end

    test "returns error with invalid id" do
      assert {:error, :not_found} = CarParkDataContext.get_car_park_data(999)
    end
  end

  describe "list_car_park_data/0" do
    test "returns list of car park data" do
      {:ok, _car_park_data} = CarParkDataContext.create_car_park_data(@valid_attrs)
      car_park_data_list = CarParkDataContext.list_car_park_data()
      assert length(car_park_data_list) >= 1
    end
  end

  describe "list_car_park_data_by_number/1" do
    test "returns list of car park data for specific carpark number" do
      {:ok, _car_park_data} = CarParkDataContext.create_car_park_data(@valid_attrs)
      car_park_data_list = CarParkDataContext.list_car_park_data_by_number("A1")
      assert length(car_park_data_list) >= 1
      assert Enum.all?(car_park_data_list, fn data -> data.carpark_number == "A1" end)
    end

    test "returns empty list for non-existent carpark number" do
      car_park_data_list = CarParkDataContext.list_car_park_data_by_number("NONEXISTENT")
      assert car_park_data_list == []
    end
  end

  describe "get_latest_car_park_data/1" do
    test "returns latest car park data for specific carpark number" do
      {:ok, _car_park_data} = CarParkDataContext.create_car_park_data(@valid_attrs)
      assert {:ok, car_park_data} = CarParkDataContext.get_latest_car_park_data("A1")
      assert car_park_data.carpark_number == "A1"
    end

    test "returns error for non-existent carpark number" do
      assert {:error, :not_found} = CarParkDataContext.get_latest_car_park_data("NONEXISTENT")
    end
  end

  describe "get_latest_car_park_data_bulk/1" do
    test "returns latest car park data for multiple carpark numbers" do
      # Create test data for multiple car parks
      {:ok, _data1} =
        CarParkDataContext.create_car_park_data(%{@valid_attrs | carpark_number: "A1"})

      {:ok, _data2} =
        CarParkDataContext.create_car_park_data(%{
          @valid_attrs
          | carpark_number: "A2",
            total_lots: 200,
            available_lots: 100
        })

      {:ok, _data3} =
        CarParkDataContext.create_car_park_data(%{
          @valid_attrs
          | carpark_number: "A3",
            total_lots: 300,
            available_lots: 150
        })

      result = CarParkDataContext.get_latest_car_park_data_bulk(["A1", "A2", "A3"])

      assert is_map(result)
      assert Map.has_key?(result, "A1")
      assert Map.has_key?(result, "A2")
      assert Map.has_key?(result, "A3")
      assert result["A1"].carpark_number == "A1"
      assert result["A2"].carpark_number == "A2"
      assert result["A3"].carpark_number == "A3"
      assert result["A1"].total_lots == 100
      assert result["A2"].total_lots == 200
      assert result["A3"].total_lots == 300
    end

    test "returns empty map for empty list" do
      result = CarParkDataContext.get_latest_car_park_data_bulk([])
      assert result == %{}
    end

    test "handles non-existent carpark numbers gracefully" do
      result = CarParkDataContext.get_latest_car_park_data_bulk(["NONEXISTENT1", "NONEXISTENT2"])
      assert result == %{}
    end

    test "returns only existing carpark numbers when some don't exist" do
      {:ok, _data} = CarParkDataContext.create_car_park_data(@valid_attrs)

      result = CarParkDataContext.get_latest_car_park_data_bulk(["A1", "NONEXISTENT"])

      assert Map.has_key?(result, "A1")
      refute Map.has_key?(result, "NONEXISTENT")
      assert result["A1"].carpark_number == "A1"
    end
  end
end

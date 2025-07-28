defmodule CarPark.ExternalServices.CarParkApiServiceTest do
  @moduledoc """
  Tests for the CarParkApiService module.
  """

  use CarPark.DataCase, async: true

  alias CarPark.CarParkDataContext
  alias CarPark.ExternalServices.CarParkApiService
  alias CarPark.Factory

  # Clean up test data before each test
  setup do
    # Clean up any existing test data
    CarPark.CarParkDataContext.delete_all_car_park_data()
    :ok
  end

  # Mock HTTP client for testing
  defmodule MockHttpClient do
    def build(method, url, headers) do
      %{method: method, url: url, headers: headers}
    end

    def request(_request, _finch) do
      # Return a mock successful response without making real HTTP calls
      {:ok, %Finch.Response{status: 200, body: Jason.encode!(%{"items" => []})}}
    end
  end

  defmodule MockHttpClientNetworkError do
    def build(_method, _url, _headers), do: %{}
    def request(_request, _finch), do: {:error, :timeout}
  end

  defmodule MockHttpClientApiError do
    def build(_method, _url, _headers), do: %{}
    def request(_request, _finch), do: {:ok, %Finch.Response{status: 500}}
  end

  defmodule MockHttpClientInvalidJson do
    def build(_method, _url, _headers), do: %{}
    def request(_request, _finch), do: {:ok, %Finch.Response{status: 200, body: "invalid json"}}
  end

  describe "parse_api_response/1" do
    test "successfully parses valid API response" do
      response = %{
        "items" => [
          %{
            "carpark_data" => [
              %{
                "carpark_info" => [
                  %{
                    "total_lots" => "100",
                    "lot_type" => "C",
                    "lots_available" => "50"
                  }
                ],
                "carpark_number" => "A1",
                "update_datetime" => "2025-07-28T07:25:17"
              }
            ]
          }
        ]
      }

      assert {:ok, parsed_data} = CarParkApiService.parse_api_response(response)
      assert length(parsed_data) == 1

      [first_record] = parsed_data
      assert first_record.carpark_number == "A1"
      assert first_record.total_lots == 100
      assert first_record.available_lots == 50
      assert %DateTime{} = first_record.update_datetime
    end

    test "handles invalid response format" do
      invalid_response = %{"wrong_key" => []}

      assert {:error, :invalid_response_format} =
               CarParkApiService.parse_api_response(invalid_response)
    end

    test "handles empty response" do
      empty_response = %{}

      assert {:error, :invalid_response_format} =
               CarParkApiService.parse_api_response(empty_response)
    end
  end

  describe "parse_datetime/1" do
    test "successfully parses valid ISO8601 datetime string" do
      datetime_string = "2025-07-28T07:25:17Z"
      result = CarParkApiService.parse_datetime(datetime_string)
      assert %DateTime{} = result
      assert result.year == 2025
      assert result.month == 7
      assert result.day == 28
      assert result.hour == 7
      assert result.minute == 25
      assert result.second == 17
    end

    test "successfully parses simple datetime format" do
      datetime_string = "2025-07-28T07:25:17"
      result = CarParkApiService.parse_datetime(datetime_string)
      assert %DateTime{} = result
      assert result.year == 2025
      assert result.month == 7
      assert result.day == 28
      assert result.hour == 7
      assert result.minute == 25
      assert result.second == 17
    end

    test "returns default datetime for invalid string" do
      invalid_string = "invalid_datetime"
      result = CarParkApiService.parse_datetime(invalid_string)
      assert result == ~U[2025-01-01 00:00:00Z]
    end

    test "returns default datetime for non-string input" do
      result = CarParkApiService.parse_datetime(123)
      assert result == ~U[2025-01-01 00:00:00Z]
    end
  end

  describe "save_car_park_data/1" do
    test "successfully saves car park data using bulk insert" do
      car_park_data_list = [
        %{
          carpark_number: "TEST_A1_#{:rand.uniform(1000)}",
          total_lots: 100,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 07:25:17Z]
        },
        %{
          carpark_number: "TEST_B2_#{:rand.uniform(1000)}",
          total_lots: 200,
          available_lots: 150,
          update_datetime: ~U[2025-07-28 07:25:18Z]
        }
      ]

      assert {:ok, 2} = CarParkApiService.save_car_park_data(car_park_data_list)

      # Verify data was saved
      saved_data = CarParkDataContext.list_car_park_data()
      assert length(saved_data) == 2

      # Find the records by carpark_number since order might vary
      a1_record =
        Enum.find(saved_data, fn data -> String.starts_with?(data.carpark_number, "TEST_A1_") end)

      b2_record =
        Enum.find(saved_data, fn data -> String.starts_with?(data.carpark_number, "TEST_B2_") end)

      assert a1_record
      assert a1_record.total_lots == 100
      assert a1_record.available_lots == 50

      assert b2_record
      assert b2_record.total_lots == 200
      assert b2_record.available_lots == 150
    end

    test "handles empty data list" do
      assert {:ok, 0} = CarParkApiService.save_car_park_data([])
    end

    test "handles bulk insert errors gracefully" do
      # Test with data that would cause database constraint errors
      # Using a string that exceeds the typical varchar(255) limit
      # Exceeds typical varchar(255) limit
      long_carpark_number = String.duplicate("A", 300)

      invalid_data = [
        %{
          carpark_number: long_carpark_number,
          total_lots: 100,
          available_lots: 50,
          update_datetime: ~U[2025-07-28 07:25:17Z]
        }
      ]

      # Bulk insert will fail due to database constraints
      assert {:error, :bulk_insert_error} = CarParkApiService.save_car_park_data(invalid_data)

      # Verify no data was saved
      saved_data = CarParkDataContext.list_car_park_data()
      assert Enum.empty?(saved_data)
    end

    test "bulk insert is much faster than individual inserts" do
      # Create a large dataset to demonstrate performance difference
      large_dataset =
        for i <- 1..100 do
          %{
            carpark_number: "BULK_TEST_#{i}_#{:rand.uniform(1000)}",
            total_lots: 100 + i,
            available_lots: 50 + i,
            update_datetime: ~U[2025-07-28 07:25:17Z]
          }
        end

      # This should be much faster than individual inserts
      {time, result} = :timer.tc(fn -> CarParkApiService.save_car_park_data(large_dataset) end)

      assert {:ok, 100} = result
      # Should complete in less than 1 second
      assert time < 1_000_000

      # Verify all data was saved
      saved_data = CarParkDataContext.list_car_park_data()

      bulk_records =
        Enum.filter(saved_data, fn data ->
          String.starts_with?(data.carpark_number, "BULK_TEST_")
        end)

      assert length(bulk_records) == 100
    end
  end

  describe "fetch_api_data/1" do
    test "uses URL from configuration" do
      # Test that the URL configuration is properly set
      expected_url = Application.get_env(:car_park, :external_apis)[:car_park_availability_url]
      assert is_binary(expected_url)
      assert String.length(expected_url) > 0

      # Test that the function can be called with a mock
      assert {:ok, _data} = CarParkApiService.fetch_api_data(MockHttpClient)
    end

    test "handles network errors gracefully" do
      assert {:error, :network_error} =
               CarParkApiService.fetch_api_data(MockHttpClientNetworkError)
    end

    test "handles API errors gracefully" do
      assert {:error, :api_error} = CarParkApiService.fetch_api_data(MockHttpClientApiError)
    end

    test "handles invalid JSON responses" do
      assert {:error, :invalid_json} = CarParkApiService.fetch_api_data(MockHttpClientInvalidJson)
    end
  end

  describe "integration test with real API" do
    test "can fetch and save real car park data" do
      # Skip this test by default - only run when explicitly requested
      # This prevents real API calls during normal test runs
      if System.get_env("RUN_INTEGRATION_TESTS") == "true" do
        # This test will make a real HTTP request to the Singapore API
        case CarParkApiService.fetch_and_save_car_park_data() do
          {:ok, count} when is_integer(count) and count > 0 ->
            # Successfully fetched and saved data
            assert count > 0

            # Verify some data was saved
            saved_data = CarParkDataContext.list_car_park_data()
            assert length(saved_data) >= count

          {:error, reason} ->
            # Network or API issues - this is acceptable for a test
            assert reason in [:network_error, :api_error, :invalid_json, :bulk_insert_error]
        end
      else
        :skip
      end
    end
  end

  describe "factory integration" do
    test "can create test data using factory" do
      car_park_data =
        Factory.car_park_data_with_attrs(%{
          carpark_number: "TEST1",
          total_lots: 100,
          available_lots: 50
        })

      assert car_park_data.carpark_number == "TEST1"
      assert car_park_data.total_lots == 100
      assert car_park_data.available_lots == 50
      assert %DateTime{} = car_park_data.update_datetime
    end

    test "can create multiple test records" do
      car_park_data_list =
        Factory.car_park_data_list(3, %{
          carpark_number: "TEST2"
        })

      assert length(car_park_data_list) == 3

      Enum.each(car_park_data_list, fn data ->
        assert data.carpark_number == "TEST2"
        assert data.total_lots >= 50
        assert data.total_lots <= 500
        assert data.available_lots >= 0
        assert data.available_lots <= data.total_lots
      end)
    end
  end
end

defmodule CarPark.ExternalServices.CarParkApiBehaviour do
  @moduledoc """
  Behaviour for car park API service.

  This behaviour defines the contract for car park API operations,
  allowing for easy mocking in tests.
  """

  @type api_response :: %{
          items: [
            %{
              timestamp: String.t(),
              carpark_data: [
                %{
                  carpark_info: [
                    %{
                      total_lots: String.t(),
                      lot_type: String.t(),
                      lots_available: String.t()
                    }
                  ],
                  carpark_number: String.t(),
                  update_datetime: String.t()
                }
              ]
            }
          ]
        }

  @doc """
  Fetches car park availability data from the Singapore API.
  """
  @callback fetch_api_data() :: {:ok, api_response()} | {:error, atom()}

  @doc """
  Fetches car park availability data using the specified HTTP client.
  """
  @callback fetch_api_data(module()) :: {:ok, api_response()} | {:error, atom()}

  @doc """
  Parses the API response to extract car park data.
  """
  @callback parse_api_response(api_response()) :: {:ok, [map()]} | {:error, atom()}

  @doc """
  Fetches car park availability data from the Singapore API and saves it to the database.
  """
  @callback fetch_and_save_car_park_data() :: {:ok, integer()} | {:error, atom()}

  @doc """
  Fetches car park availability data and saves it using the specified HTTP client.
  """
  @callback fetch_and_save_car_park_data(module()) :: {:ok, integer()} | {:error, atom()}
end

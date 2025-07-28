defmodule CarParkWeb.CarParkControllerTest do
  @moduledoc """
  Tests for the CarParkController module.
  """

  use CarParkWeb.ConnCase

  describe "nearest/2" do
    test "returns nearest car parks with valid coordinates", %{conn: conn} do
      # Test with valid coordinates
      conn = get(conn, ~p"/carparks/nearest?latitude=1.3521&longitude=103.8198")

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert Map.has_key?(response, "data")
      assert Map.has_key?(response, "pagination")
      assert Map.has_key?(response, "timestamp")

      # Check pagination metadata
      pagination = response["pagination"]
      assert Map.has_key?(pagination, "total_count")
      assert Map.has_key?(pagination, "page")
      assert Map.has_key?(pagination, "per_page")
      assert Map.has_key?(pagination, "total_pages")
      assert is_integer(pagination["total_count"])
      assert is_integer(pagination["page"])
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["total_pages"])
    end

    test "returns nearest car parks with pagination", %{conn: conn} do
      # Test with pagination parameters
      conn = get(conn, ~p"/carparks/nearest?latitude=1.3521&longitude=103.8198&page=1&per_page=5")

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert Map.has_key?(response, "data")
      assert Map.has_key?(response, "pagination")
      assert Map.has_key?(response, "timestamp")

      # Check pagination metadata
      pagination = response["pagination"]
      assert pagination["page"] == 1
      assert pagination["per_page"] == 5
      assert pagination["total_count"] >= 0
      assert pagination["total_pages"] >= 0
    end

    test "returns error with missing latitude", %{conn: conn} do
      conn = get(conn, ~p"/carparks/nearest?longitude=103.8198")

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "Invalid parameters")
    end

    test "returns error with missing longitude", %{conn: conn} do
      conn = get(conn, ~p"/carparks/nearest?latitude=1.3521")

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "Invalid parameters")
    end

    test "returns error with invalid latitude format", %{conn: conn} do
      conn = get(conn, ~p"/carparks/nearest?latitude=invalid&longitude=103.8198")

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "Invalid parameters")
    end

    test "returns error with invalid longitude format", %{conn: conn} do
      conn = get(conn, ~p"/carparks/nearest?latitude=1.3521&longitude=invalid")

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "Invalid parameters")
    end

    test "returns error with invalid page parameter", %{conn: conn} do
      conn = get(conn, ~p"/carparks/nearest?latitude=1.3521&longitude=103.8198&page=invalid")

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "Invalid parameters")
    end

    test "returns error with invalid per_page parameter", %{conn: conn} do
      conn = get(conn, ~p"/carparks/nearest?latitude=1.3521&longitude=103.8198&per_page=invalid")

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "Invalid parameters")
    end

    test "uses default pagination when not provided", %{conn: conn} do
      conn = get(conn, ~p"/carparks/nearest?latitude=1.3521&longitude=103.8198")

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert Map.has_key?(response, "data")
      assert Map.has_key?(response, "pagination")
      assert Map.has_key?(response, "timestamp")

      # Check default pagination values
      pagination = response["pagination"]
      assert pagination["page"] == 1
      assert pagination["per_page"] == 10
    end
  end
end

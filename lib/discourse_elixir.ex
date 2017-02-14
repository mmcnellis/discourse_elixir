defmodule DiscourseElixir do
  use HTTPoison.Base

  @endpoint Application.get_env(:discourse_elixir, :discourse_endpoint)
  @username Application.get_env(:discourse_elixir, :discourse_username)
  @api_key Application.get_env(:discourse_elixir, :discourse_api_key)

  @expected_fields ~w(success message errors user_id user user_badges)

  @moduledoc """
  This is a Discourse client for Elixir that builds upon HTTPoison.Base.

  This module is primarily intended to allow for the creation and management of
  Discourse users. More functionality may be added, though it is not a priority.
  """

  def process_url(url) do
    @endpoint <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode! 
    |> Map.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def user_id(username) do
    url = "/users/#{username}.json"

    case get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body[:user]["id"]
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        "Resource not found"
      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end

  def user(username) do
    url = "/users/#{username}.json"

    case get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        "Resource not found"
      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end

  def create_user(name, email, password) do
    url = "/users?api_key=#{@api_key}&api_username=#{@username}"

    case post url, {:form, [{"name", name}, {"username", name}, {"email", email}, {"password", password}, {"active", true}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: [errors: errors, message: _, success: success]}} ->
        %{:errors => errors, :success => success}
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
        "Internal server error"
      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end
end

defmodule DiscourseElixir do
  use HTTPoison.Base
  alias HTTPoison.Error

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
    |> Enum.into %{}
  end

  @doc """
  Issues a GET request for the given user, returning the user's id or that the user doesn't
  exist

  This function returns `{:ok, value}` if the request is successful, `{:error, reason}`
  otherwise.
  """
  @spec user_id(string) :: {:ok, integer | string} | {:error, Error.t}
  def user_id(username) do
    url = "/users/#{username}.json"

    case get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body[:user]["id"]}
      {:ok, %HTTPoison.Response{status_code: 404, body: _}} ->
        {:ok, "User not found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a GET request for the given user, returning the user's id or that the user doesn't
  exist, and raising an error if it fails.

  This function works the same as `user_id/1` but only returns `value` when there is a
  successful request. If the request fails, an error is raised.
  """
  @spec user_id!(string) :: integer | string | Error.t
  def user_id!(username) do
    case user_id(username) do
      {:ok, response} -> response
      {:error, %Error{reason: reason}} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a GET request for the given user, returning the full response body or that the
  user doesn't exist.

  If successful, returns `{:ok, %{user: %{"foo" => "bar", ...}, user_badges: []}}` or
  `{:ok, "User not found"}` If an error is raised, returns `{:error, reason}`
  """
  @spec user(string) :: {:ok, map | string} | {:error, Error.t}
  def user(username) do

    url = "/users/#{username}.json"

    case get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 404, body: _}} ->
        {:ok, "User not found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a GET request for the given user, returning the full response body or that the
  user doesn't exist, and raising an error if the request fails.

  This function works the same as `user/1` but only returns the body when the request is
  successful. If the request fails, an error is raised.
  """
  @spec user!(string) :: map | string | Error.t
  def user!(username) do
    case user(username) do
      {:ok, response} -> response
      {:error, %Error{reason: reason}} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a POST request to create a user with the provided params.

  If successful, returns `{:ok, body}`. If Discourse doesn't create the user due to a
  username or email already being taken, or the password not being valid, returns some
  variation of `{:error,
  %{errors: %{"email" => [],
  "password" => ["is too short (minimum is 10 characters)"],
  "username" => ["must be unique"]}}}` If HTTPoison throws an error, returns `{:error, reason}`
  """
  @spec create_user(string, string, string) :: {:ok, map | string} | {:error, map | Error.t}
  def create_user(name, email, password) do
    url = "/users?api_key=#{@api_key}&api_username=#{@username}"

    case post url, {:form, [{"name", name}, {"username", name}, {"email", email}, {"password", password}, {"active", true}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: %{errors: errors, message: _, success: _}}} ->
        {:error, %{:errors => errors}}
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      # {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
      #   {:error, "Internal server error"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a POST request to create a user with the provided params, raising an error if
  the request fails.

  This function works the same way as `create_user/3` but only returns the response when
  the request is successful. If the request fails, an error is raised.
  """
  @spec create_user!(string, string, string) :: map | string | Error.t
  def create_user!(name, email, password) do
    case create_user(name, email, password) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a PUT request to deactivate the given user.

  If successful, returns `{:ok, "User has been deactivated}` or `{:ok, "User does not exist}`
  and if the request fails, returns `{:error, reason}`
  """
  @spec deactivate_user(string) :: {:ok, string} | {:error, Error.t}
  def deactivate_user(username) do
    url = "/users/#{username}?api_key=#{@api_key}&api_username=#{@username}"

    case put url, {:form, [{"username", username}, {"active", false}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body.success}
      {:ok, %HTTPoison.Response{status_code: 404, body: _}} ->
        {:ok, "User not found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a PUT request to deactivate the given user.

  If successful, returns `{:ok, "OK"}` or `{:ok, "User not found"}`
  and if the request fails, returns `{:error, reason}`
  """
  @spec deactivate_user!(string) :: string
  def deactivate_user!(username) do
    case deactivate_user(username) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a PUT request to reactivate the given user.

  If successful, returns `{:ok, "User has been deactivated}` or `{:ok, "User does not exist}`
  and if the request fails, returns `{:error, reason}`
  """
  @spec reactivate_user(string) :: {:ok, string} | {:error, Error.t}
  def reactivate_user(username) do
    url = "/users/#{username}?api_key=#{@api_key}&api_username=#{@username}"

    case put url, {:form, [{"username", username}, {"active", true}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body.success}
      {:ok, %HTTPoison.Response{status_code: 404, body: _}} ->
        {:ok, "User not found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @dox """
  Issues a PUT request to reactivate the given user, raising an error if the request fails.

  This function works the same way as `reactivate_user/1` but only returns the response when
  the request is successful. If the request fails, an error is raised.
  """
  @spec reactivate_user!(string) :: string
  def reactivate_user!(username) do
    case reactivate_user(username) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end
end

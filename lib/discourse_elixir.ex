defmodule DiscourseElixir do
  use HTTPoison.Base
  alias HTTPoison.Error

  @endpoint Application.get_env(:discourse_elixir, :discourse_endpoint)
  @username Application.get_env(:discourse_elixir, :discourse_username)
  @api_key Application.get_env(:discourse_elixir, :discourse_api_key)

  @expected_fields ~w(success message errors user_id user user_badges api_key category)

  @moduledoc """
  This is a Discourse client for Elixir that builds upon HTTPoison.Base.

  This module is primarily intended to allow for the creation and management of
  Discourse users. More functionality may be added, though it is not a priority.
  """

  def process_url(url) do
    @endpoint <> url
  end

  def process_response_body(body) do
    case Poison.decode body do
      {:ok, body} ->
        body
        |> Map.take(@expected_fields)
        |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
        |> Enum.into %{}
        # This workaround is due to Discourse returning 200 with text/plain and an empty
        # body on revoke_api_key success, which causes a Poison decoding error.
      {:error, _} ->
        body
    end

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
  @spec create_user!(string, string, string) :: map | string | no_return
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
  @spec deactivate_user!(string) :: string | no_return
  def deactivate_user!(username) do
    case deactivate_user(username) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a PUT request to reactivate the given user.

  If successful, returns `{:ok, "User has been deactivated}` or `{:ok, "User does not exist"}`
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

  @doc """
  Issues a PUT request to reactivate the given user, raising an error if the request fails.

  This function works the same way as `reactivate_user/1` but only returns the response when
  the request is successful. If the request fails, an error is raised.
  """
  @spec reactivate_user!(string) :: string | no_return
  def reactivate_user!(username) do
    case reactivate_user(username) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a POST request to generate an API key for the given user_id.

  If successful, returns `{:ok, "api key"}` and if the request fails, returns `{error: reason}`
  """
  @spec generate_user_api_key(integer) :: {:ok, string} | {:error, Error.t}
  def generate_user_api_key(user_id) do
    url = "/admin/users/#{user_id}/generate_api_key"

    case post url, {:form, [{"api_username", @username}, {"api_key", @api_key}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body.api_key["key"]}
      {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
        {:error, "Internal server error (500 status code)"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a POST request to generate an API key for the given user_id, raising an error if
  the request fails.

  This function works the same way as `generate_user_api_key/1` but only returns the
  api_key string when the request is successful. If the request fails, an error is raised.
  """
  @spec generate_user_api_key!(integer) :: string
  def generate_user_api_key!(user_id) do
    case generate_user_api_key(user_id) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a POST request to revoke an API key for the given user_id.

  If successful, returns `{:ok, "Successfully revoked the api key"}` and if the request
  fails, returns `{error: reason}`
  """
  @spec revoke_user_api_key(integer) :: {:ok, string} | {:error, Error.t}
  def revoke_user_api_key(user_id) do
    url = "/admin/users/#{user_id}/revoke_api_key"

    # For some reason, `delete url, {:form, [...]}` doesn't work.
    # It seems like HTTPoison improperly calls :proplists.get_value/2 with a third
    # argument, `:undefined`, when using HTTPoison.delete/1 but not when using request/1
    # with :delete as the first argument (which _should_ be what delete/3 does)
    # However, when using request/3 directly the endpoint doesn't return json, and
    # thus Poison.decode!/1 in process_response_body/1 makes it throw an error.

    case request :delete, url, {:form, [{"api_username", @username}, {"api_key", @api_key}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, "API key successfully revoked"}
      {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
        {:error, "Internal server error (500 status code)"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a POST request to revoke an API key for the given user_id, raising an error if
  the request fails.

  This function works the same way as `revoke_user_api_key/1` but only returns the
  response when the request is successful. If the request fails, an error is raised.
  """
  @spec revoke_user_api_key!(integer) :: string
  def revoke_user_api_key!(user_id) do
    case revoke_user_api_key(user_id) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a POST request to create a community topic for the given company name, and generates
  all of its proper subcategories as well.

  If successful, returns {:ok, category}, otherwise returns {:error, reason}
  """
  @spec create_community_topic(string, string) :: {:ok, map} | {:error, Error.t}
  def create_community_topic(name, color) do
    url = "/categories"

    case post url, {:form, [{"api_username", @username}, {"api_key", @api_key}, {"name", name}, {"color", color}, {"text_color", color}, {"description", "Keep in touch with reps, learn new products, crowd source ideas"}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
        {:error, "Internal server error (500 status code)"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a POST request to create a community topic for the given company name, and generates
  all of its proper subcategories as well.

  This function works the same way as `create_community_topic` but only returns the
  response when the request is successful. If the request fails, an error is raised.
  """
  @spec create_community_topic!(string, string) :: map | no_return
  def create_community_topic!(name, color) do
    case create_community_topic(name, color) do
      {:ok, response} -> response
      {:error, reason} -> raise Error, reason: reason
    end
  end

  @doc """
  Issues a POST request to create a subcategory for the community topic category whose id is
  provided.

  If successful, returns {:ok, category}, otherwise returns {:error, reason}
  """
  @spec create_category(string, string, integer, string, string) :: {:ok, map} | {:error, Error.t}
  def create_category(name, color, category_id, description, icon) do
    url = "/categories"

    case post url, {:form, [{"api_username", @username}, {"api_key", @api_key}, {"name", name}, {"color", color}, {"text_color", color}, {"parent_category_id", category_id}, {"description", description}, {"icon", icon}]} do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
        {:error, "Internal server error (500 status code)"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Issues a POST request to create a subcategory for the community topic category whose id is
  provided.

  This function works the same way as `create_category` but only returns the
  category when the request is successful. If the request fails, an error is raised.
  """
  @spec create_category!(string, string, integer, string, string) :: map | no_return
  def create_category!(name, color, category_id, description, icon) do
    case create_category(name, color, category_id, description, icon) do
      {:ok, body} -> body
      {:error, reason} -> raise Error, reason: reason
    end
  end
end

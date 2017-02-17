# DiscourseElixir

A Discourse client for Elixir.

## Installation

Add `discourse_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:discourse_elixir, "~> 0.4.0"}]
end
```

Then update *YOUR* project's `config/config.exs` with your `discourse_api_key`, `discourse_username`, and `discourse_endpoint`.
For reference, check this project's `config/config.exs`

To generate docs, run `mix docs`

Currently supports these functions:

```elixir
create_user(username, password, email)

user(username)

user_id(username)

generate_user_api_key(user_id)

revoke_user_api_key(user_id)

deactivate_user(username)

reactivate_user(username)
```
More details about these functions can be seen by generating the docs or by viewing the specs and docs within `/lib/discourse_elixir`

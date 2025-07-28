# CarPark

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Code Quality Tools

This project uses several tools to maintain high code quality:

### Credo - Static Code Analysis

```bash
# Run code analysis
mix credo

# Run with strict settings
mix credo --strict

# Explain specific issues
mix credo explain
```

### Dialyzer - Type Checking

```bash
# Run type checking
mix dialyzer

# Build PLT (first time only)
mix dialyzer --plt
```

### TypedEctoSchema - Type-Safe Schemas

This project uses `typed_ecto_schema` for type-safe Ecto schemas. When creating new schemas, use the `typed_schema` macro:

```elixir
defmodule CarPark.Schemas.User do
  use TypedEctoSchema

  typed_schema "users" do
    field :email, :string
    field :name, :string
    timestamps()
  end
end
```

### Code Quality Aliases

```bash
# Run all code quality checks
mix code.check

# Fix auto-fixable issues
mix code.fix
```

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

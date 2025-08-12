defmodule Todo.Repo do
  use Ecto.Repo,
    otp_app: :todo,
    adapter: Ecto.Adapters.Postgres

  IO.inspect("Avviato la Repo")
end

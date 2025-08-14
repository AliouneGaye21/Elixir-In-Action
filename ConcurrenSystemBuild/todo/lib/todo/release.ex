defmodule Todo.Release do
  @app :todo

  def migrate do
    IO.puts("Running migrations...")

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    IO.puts("Migrations complete.")
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end
end

defmodule Todo.Repo.Migrations.CreateEntries do
  use Ecto.Migration

 def change do
    create table(:entries) do
      add :title, :string, null: false
      add :date, :date, null: false
      timestamps()
    end
  end
end

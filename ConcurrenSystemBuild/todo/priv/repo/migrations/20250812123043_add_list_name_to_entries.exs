defmodule Todo.Repo.Migrations.AddListNameToEntries do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :list_name, :string, null: false
    end
  end
end

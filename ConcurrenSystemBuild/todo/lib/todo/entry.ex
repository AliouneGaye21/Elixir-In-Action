defmodule Todo.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  # "entries" è il nome della tabella nel database
  schema "entries" do
    # Definiamo i campi e i loro tipi
    field(:title, :string)
    field(:date, :date)
    field(:list_name, :string)
    # `belongs_to` per le relazioni (se necessario)
    # field :list_id, :id

    # Aggiunge automaticamente i campi `inserted_at` e `updated_at`
    timestamps()
  end

  # Funzione per creare un changeset per validare i dati
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :date, :list_name])
    |> validate_required([:title, :date, :list_name])
  end
end

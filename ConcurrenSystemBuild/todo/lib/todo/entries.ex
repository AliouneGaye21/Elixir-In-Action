defmodule Todo.Entries do
  # Alias per accedere più facilmente al Repo e allo Schema
  alias Todo.Repo
  alias Todo.Entry

  # Importa Ecto.Query per scrivere le query
  import Ecto.Query

  @doc """
  Recupera tutte le voci per una data specifica.
  """
  def get_entries_by_date(list_name, date) do
    query =
      from(e in Entry,
        where: e.date == ^date and e.list_name == ^list_name
      )

    Repo.all(query)
  end

  @doc """
  Crea una nuova voce nel database.
  Riceve una mappa di attributi (es. %{title: "...", date: ...}).
  """
  def create_entry(list_name, attrs) do
    # Aggiungi il list_name agli attributi prima di creare il changeset
    attrs_with_list_name = Map.put(attrs, :list_name, list_name)

    %Entry{}
    |> Entry.changeset(attrs_with_list_name)
    |> Repo.insert()
  end

  @doc """
  Recupera una voce specifica per ID e lista.
  restituisce nil se non trovata.
  altrimenti restituisce l'Entry cancellato.
  """
  def delete_entry(list_name, entry_id) do
    # 1. Trova la voce, assicurandoci che appartenga alla lista corretta.
    case get_entry(list_name, entry_id) do
      nil ->
        {:error, :not_found}

      entry ->
        # 2. Se esiste, la cancelliamo.
        Repo.delete(entry)
    end
  end

  @doc """
  Aggiorna una voce esistente.
  Riceve il nome della lista, l'ID della voce e gli attributi da aggiornare.
  Restituisce {:ok, entry} se l'aggiornamento ha successo,
  oppure {:error, changeset} se ci sono errori.
  Se la voce non esiste, restituisce {:error, :not_found}.
  """
  def update_entry(list_name, entry_id, attrs) do
    # 1. Trova la voce che vogliamo aggiornare.
    # Usiamo `get_entry` per assicurarci che appartenga alla lista corretta.
    case get_entry(list_name, entry_id) do
      nil ->
        # Se la voce non esiste, restituiamo un errore.
        {:error, :not_found}

      entry ->
        # 2. Se esiste, applichiamo le modifiche tramite un changeset e aggiorniamo.
        entry
        |> Entry.changeset(attrs)
        |> Repo.update()
    end
  end

  defp get_entry(list_name, entry_id) do
    Repo.get_by(Entry, id: entry_id, list_name: list_name)
  end
end

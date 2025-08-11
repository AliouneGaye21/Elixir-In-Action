defmodule Todo.List do
  # Definisce la struttura dati per una to-do list.
  # `next_id` è un contatore per assegnare ID univoci alle nuove voci.
  # `entries` è una mappa che contiene le voci, usando il loro ID come chiave.
  defstruct next_id: 1, entries: %{}

  # Costruttore per la `Todo.List`. Può creare una lista vuota
  # o popolarla con una lista iniziale di voci.
  def new(entries \\ []) do
    # Usa `Enum.reduce` per costruire iterativamente la struttura `Todo.List`.
    Enum.reduce(
      entries,
      # L'accumulatore iniziale è una struct `Todo.List` vuota.
      %Todo.List{},
      # Per ogni `entry` nella lista di input, chiama `add_entry`.
      # La versione commentata `&add_entry(&2, &1)` è una scorciatoia per la stessa logica.
      fn entry, todo_list_acc ->
        add_entry(todo_list_acc, entry)
      end
    )
  end

  # --- VECCHIA IMPLEMENTAZIONE (ORA COMMENTATA) ---
  # Questa era una versione precedente del costruttore che si appoggiava
  # all'astrazione `MultiDict`.
  # def new(), do: MultiDict.new()

  # Aggiunge una nuova voce alla to-do list.
  def add_entry(todo_list, entry) do
    # Assegna un ID univoco alla nuova voce, prendendolo dal contatore `next_id`.
    entry = Map.put(entry, :id, todo_list.next_id)

    # Inserisce la nuova voce (con il suo ID) nella mappa delle voci.
    new_entries =
      Map.put(
        todo_list.entries,
        todo_list.next_id,
        entry
      )

    # Ritorna una *nuova* struct `Todo.List` aggiornata, in linea con il principio
    # di immutabilità di Elixir.
    %Todo.List{todo_list | entries: new_entries, next_id: todo_list.next_id + 1}
  end

  # Restituisce tutte le voci per una data specifica.
  def entries(todo_list, date) do
    todo_list.entries
    # Estrae tutti i valori (le voci) dalla mappa.
    |> Map.values()
    # Filtra la lista per tenere solo le voci con la data corrispondente.
    |> Enum.filter(&(&1.date == date))
  end

  # Aggiorna una voce esistente.
  # Riceve l'ID della voce e una funzione `updater_fun` che, dato il vecchio valore,
  # calcola e restituisce il nuovo valore.
  def update_entry(todo_list, entry_id, updater_fun) do
    # Cerca la voce nella mappa in modo sicuro.
    case Map.fetch(todo_list.entries, entry_id) do
      # Se la voce non esiste, ritorna la lista originale senza modifiche.
      :error ->
        todo_list

      # Se la voce esiste...
      {:ok, old_entry} ->
        # ...applica la funzione di aggiornamento per ottenere la nuova voce.
        new_entry = updater_fun.(old_entry)
        # Sostituisce la vecchia voce con la nuova nella mappa.
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        # Ritorna una nuova struct `Todo.List` con la mappa aggiornata.
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  # Rimuove una voce dalla to-do list dato il suo ID.
  def delete_entry(todo_list, entry_id) do
    # Controlla se la chiave (ID) esiste nella mappa.
    case Map.has_key?(todo_list.entries, entry_id) do
      # Se non esiste, ritorna la lista non modificata.
      false ->
        todo_list

      # Se esiste...
      true ->
        # ...rimuove la voce dalla mappa.
        new_entries = Map.delete(todo_list.entries, entry_id)
        # Ritorna una nuova struct `Todo.List` con la mappa aggiornata.
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  # Modulo innestato per gestire l'importazione di dati da un file CSV.
  defmodule CsvImporter do
    # Importa le voci da un file e restituisce una nuova `Todo.List`.
    def import(path) do
      path
      # 1. Apre il file come uno stream (lazy), non caricando tutto in memoria.
      |> File.stream!()
      # 2. `IO.inspect` è utile per il debug: mostra il contenuto dello stream.
      |> IO.inspect()
      # 3. Per ogni riga dello stream, rimuove il carattere di a capo finale.
      |> Stream.map(&String.trim_trailing(&1, "\n"))
      |> IO.inspect()
      # 4. Converte ogni riga (stringa) in una mappa di una voce.
      |> Stream.map(&parse_line/1)
      |> IO.inspect()
      # 5. Converte lo stream (lazy) in una lista (eager).
      |> Enum.to_list()
      |> IO.inspect()
      # 6. Usa la lista di mappe per creare una nuova `Todo.List`.
      |> Todo.List.new()
    end

    # Funzione privata per analizzare una singola riga del CSV.
    defp parse_line(line) do
      [date, title] = String.split(line, ",")
      %{date: Date.from_iso8601!(date), title: title}
    end
  end
end

# --- MODULO OBSOLETO ---
# Questo modulo era un'astrazione usata in una versione precedente.
# La sua logica è stata integrata direttamente in `Todo.List`.
defmodule MultiDict do
  def new(), do: %{}

  def add(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    Map.get(dict, key, [])
  end
end

# Implementa il protocollo `Collectable` per la struct `Todo.List`.
# Questo permette di usare `Enum.into` e `for` con `:into` per popolare
# direttamente una `Todo.List`.
defimpl Collectable, for: Todo.List do
  # Funzione di ingresso del protocollo. Riceve la struttura dati iniziale.
  def into(original_list) do
    # Restituisce la struttura iniziale e la funzione che gestirà l'aggiunta di ogni elemento.
    {original_list, &into_callback/2}
  end

  # Funzione "appender": chiamata per ogni elemento da aggiungere.
  defp into_callback(todo_list, {:cont, entry}) do
    # Delega la logica di aggiunta alla funzione `add_entry` del nostro modulo.
    Todo.List.add_entry(todo_list, entry)
  end

  # Chiamata alla fine del processo di collezione. Restituisce lo stato finale.
  defp into_callback(todo_list, :done), do: todo_list

  # Chiamata se il processo di collezione viene interrotto prematuramente.
  defp into_callback(_todo_list, :halt), do: :ok
end


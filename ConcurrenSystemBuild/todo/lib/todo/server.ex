defmodule Todo.Server do
  @moduledoc """
  Un processo Agent per gestire lo stato di una singola to-do list.

  Questo Agent viene avviato dinamicamente dal `Todo.Cache` quando necessario.
  Mantiene lo stato `{nome_lista, dati_lista}` e si occupa di:
  - Caricare lo stato iniziale dal `Todo.Database`.
  - Gestire le operazioni di aggiunta, aggiornamento, rimozione e lettura delle entry.
  - Persistere ogni modifica nel `Todo.Database`.
  """

  # Utilizziamo Agent come implementazione semplificata di un GenServer per la gestione dello stato. [cite: 1454]
  # La strategia di riavvio è `:temporary`: se il server crasha, il supervisore non lo riavvia
  # automaticamente. Verrà riavviato "on-demand" dal `Todo.Cache` alla prossima richiesta. [cite: 1440]
  use Agent, restart: :temporary

  ## === API Pubblica ===

  @doc """
  Avvia un nuovo processo `Todo.Server`.

  Lo stato iniziale viene caricato dal database. Se non esiste, viene creata una nuova
  to-do list vuota. Il processo viene registrato nel `Todo.ProcessRegistry`.
  """
  def start_link(name) do
    Agent.start_link(
      fn ->
        IO.puts("Starting to-do server for #{name}")
        # Lo stato dell'Agent è una tupla: {nome_della_lista, dati_della_lista}
        {name, Todo.Database.get(name) || Todo.List.new()}
      end,
      # Registra il processo usando un "via tuple" per permettere la discovery tramite nome.
      name: via_tuple(name)
    )
  end

  @doc """
  Aggiunge una nuova entry alla to-do list.

  Questa è un'operazione asincrona (`cast`).
  """
  def add_entry(todo_server, new_entry) do
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.add_entry(todo_list, new_entry)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  @doc """
  Recupera tutte le entry per una data specifica.

  Questa è un'operazione sincrona (`get`).
  """
  def entries(todo_server, date) do
    Agent.get(
      todo_server,
      fn {_name, todo_list} -> Todo.List.entries(todo_list, date) end
    )
  end

  @doc """
  Aggiorna una entry esistente tramite il suo ID.

  Questa è un'operazione asincrona (`cast`).
  """
  def update_entry(todo_server, id, updater_fun) do
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.update_entry(todo_list, id, updater_fun)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  @doc """
  Rimuove una entry tramite il suo ID.

  Questa è un'operazione asincrona (`cast`).
  """
  def delete_entry(todo_server, id) do
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.delete_entry(todo_list, id)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  ## === Funzioni Private ===

  # Helper per creare il "via tuple" necessario per la registrazione nel registry.
  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end

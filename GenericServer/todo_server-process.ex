defmodule ServerProcess do
  @moduledoc """
  Un server generico che gestisce richieste sincrone (`call`) e asincrone (`cast`)
  tramite un modulo di callback.
  """

  @doc """
  Avvia un nuovo processo server usando il modulo di callback specificato.

  ## Parametri
    - `callback_module`: Il modulo che implementa le funzioni di callback (`init/0`, `handle_call/2`, `handle_cast/2`).

  ## Ritorna
    - Il PID del processo server avviato.
  """
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  @doc """
  Invia una richiesta sincrona al server e attende la risposta.

  ## Parametri
    - `server_pid`: Il PID del processo server.
    - `request`: La richiesta da inviare.

  ## Ritorna
    - La risposta del server.
  """
  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} ->
        response
    end
  end

  @doc """
  Invia una richiesta asincrona al server (non attende risposta).

  ## Parametri
    - `server_pid`: Il PID del processo server.
    - `request`: La richiesta da inviare.
  """
  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  @doc false
  # Ciclo principale del server: gestisce i messaggi ricevuti.
  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(request, current_state)
        loop(callback_module, new_state)
    end
  end
end

defmodule TodoServer do
  @name :todo_server

  # Avvia il processo e lo registra con un nome
  def start() do
    pid = ServerProcess.start(__MODULE__)
    Process.register(pid, @name)
  end

  ## === API Pubblica ===

  def add_entry(new_entry) do
    ServerProcess.cast(@name, {:add_entry, new_entry})
  end

  def entries(date) do
    ServerProcess.call(@name, {:entries, date})
  end

  def update_entry(entry_id, updater_fun) do
    ServerProcess.cast(@name, {:update_entry, entry_id, updater_fun})
  end

  def delete_entry(entry_id) do
    ServerProcess.cast(@name, {:delete_entry, entry_id})
  end

  ## === Callback per ServerProcess ===

  def init() do
    TodoList.new()
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    TodoList.update_entry(todo_list, entry_id, updater_fun)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    TodoList.delete_entry(todo_list, entry_id)
  end

  def handle_call({:entries, date}, todo_list) do
    {TodoList.entries(todo_list, date), todo_list}
  end
end

defmodule TodoList do
  defstruct next_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      # &add_entry(&2, &1)
      fn entry, todo_list_acc ->
        add_entry(todo_list_acc, entry)
      end
    )
  end

  # def new(), do: %TodoList{}

  # def new(), do: MultiDict.new()

  def add_entry(todo_list, entry) do
    # update the entry’s id value with the value stored in the next_id
    entry = Map.put(entry, :id, todo_list.next_id)

    new_entries =
      Map.put(
        todo_list.entries,
        todo_list.next_id,
        entry
      )

    %TodoList{todo_list | entries: new_entries, next_id: todo_list.next_id + 1}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Map.values()
    |> Enum.filter(&(&1.date == date))
  end

  # I(l terzo argomento è la lamba che mi dice cosa fare con il vecchio entry
  # Il suo risultato diventa il nuovo entry che poi metto nella set degli altri
  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    case Map.has_key?(todo_list.entries, entry_id) do
      false ->
        todo_list

      true ->
        new_entries = Map.delete(todo_list.entries, entry_id)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  defmodule CsvImporter do
    def import(path) do
      path
      |> File.stream!()
      |> IO.inspect()
      |> Stream.map(&String.trim_trailing(&1, "\n"))
      |> IO.inspect()
      |> Stream.map(&parse_line/1)
      |> IO.inspect()
      |> Enum.to_list()
      |> IO.inspect()
      |> TodoList.new()
    end

    defp parse_line(line) do
      [date, title] = String.split(line, ",")
      %{date: Date.from_iso8601!(date), title: title}
    end
  end
end

defmodule MultiDict do
  def new(), do: %{}

  def add(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    Map.get(dict, key, [])
  end
end

defimpl Collectable, for: TodoServ do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end

####### ----------Script di test-----------------#######
# TodoServer.start()

# TodoServer.add_entry(%{date: ~D[2025-07-22], title: "Scrivere documentazione"})
# TodoServer.add_entry(%{date: ~D[2025-07-22], title: "Fare commit del codice"})
# TodoServer.add_entry(%{date: ~D[2025-07-23], title: "Refactoring finale"})

# TodoServer.entries(~D[2025-07-22])

# TodoServer.entries(~D[2025-07-23])

# TodoServer.update_entry(2, fn entry ->
#   %{entry | title: entry.title <> " (urgente)"}
# end)

# TodoServer.entries(~D[2025-07-22])

# TodoServer.delete_entry(1)

# TodoServer.entries(~D[2025-07-22])

# TodoServer.entries(~D[2025-07-22])
# TodoServer.entries(~D[2025-07-23])

###

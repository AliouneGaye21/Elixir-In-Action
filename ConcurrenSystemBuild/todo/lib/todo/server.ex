defmodule Todo.Server do
  use GenServer

  ## === API pubblica ===

  def start() do
    GenServer.start(__MODULE__, nil)
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  def update_entry(pid, id, updater_fun) do
    GenServer.cast(pid, {:update_entry, id, updater_fun})
  end

  def delete_entry(pid, id) do
    GenServer.cast(pid, {:delete_entry, id})
  end

  ## === Callback GenServer ===

  @impl true
  def init(_args) do
    {:ok, Todo.List.new()}
  end

  @impl true
  def handle_cast({:add_entry, entry}, state) do
    new_state = Todo.List.add_entry(state, entry)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_entry, id, fun}, state) do
    new_state = Todo.List.update_entry(state, id, fun)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:delete_entry, id}, state) do
    new_state = Todo.List.delete_entry(state, id)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:entries, date}, _from, state) do
    {:reply, Todo.List.entries(state, date), state}
  end
end

defmodule Todo.List do
  defstruct next_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %Todo.List{},
      # &add_entry(&2, &1)
      fn entry, todo_list_acc ->
        add_entry(todo_list_acc, entry)
      end
    )
  end

  # def new(), do: %Todo.List{}

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

    %Todo.List{todo_list | entries: new_entries, next_id: todo_list.next_id + 1}
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
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    case Map.has_key?(todo_list.entries, entry_id) do
      false ->
        todo_list

      true ->
        new_entries = Map.delete(todo_list.entries, entry_id)
        %Todo.List{todo_list | entries: new_entries}
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
      |> Todo.List.new()
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
    Todo.List.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end

#### ---------------TEst----------------------------
# Todo.Server.start()
# Todo.Server.add_entry(%{date: ~D[2025-07-22], title: "Scrivere GenServer"})
# Todo.Server.entries(~D[2025-07-22])
# Todo.Server.update_entry(1, fn e -> %{e | title: "Aggiornato"} end)
# Todo.Server.delete_entry(1)

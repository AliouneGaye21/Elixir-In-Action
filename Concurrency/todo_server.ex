defmodule TodoServer do
  @name :todo_server

  def start() do
    pid = spawn(fn -> loop(TodoList.new()) end)
    Process.register(pid, @name)
    pid
  end

  def add_entry(new_entry) do
    send(@name, {:add_entry, new_entry})
  end

  def entries(date) do
    caller = self()
    send(@name, {:entries, caller, date})

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  def update_entry(entry_id, updater_fun) do
    send(@name, {:update_entry, entry_id, updater_fun})
  end

  def delete_entry(entry_id) do
    send(@name, {:delete_entry, entry_id})
  end

  defp loop(todo_list) do
    new_todo_list =
      receive do
        message -> process_message(todo_list, message)
      end

    loop(new_todo_list)
  end

  defp process_message(todo_list, {:add_entry, new_entry}) do
    TodoList.add_entry(todo_list, new_entry)
  end

  defp process_message(todo_list, {:update_entry, entry_id, updater_fun}) do
    TodoList.update_entry(todo_list, entry_id, updater_fun)
  end

  defp process_message(todo_list, {:delete_entry, entry_id}) do
    TodoList.delete_entry(todo_list, entry_id)
  end

  defp process_message(todo_list, {:entries, caller, date}) do
    entries = TodoList.entries(todo_list, date)
    send(caller, {:todo_entries, entries})
    todo_list
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

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end

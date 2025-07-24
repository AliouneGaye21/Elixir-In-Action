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

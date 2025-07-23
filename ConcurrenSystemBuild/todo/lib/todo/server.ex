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


defimpl Collectable, for: Todo.Server do
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

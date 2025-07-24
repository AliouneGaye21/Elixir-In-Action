defmodule Todo.Server do
  use GenServer

  ## === API pubblica ===

  # the name is the to-do list name 
  def start(name) do
    GenServer.start(__MODULE__, name)
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def update_entry(todo_server, id, updater_fun) do
    GenServer.cast(todo_server, {:update_entry, id, updater_fun})
  end

  def delete_entry(todo_server, id) do
    GenServer.cast(todo_server, {:delete_entry, id})
  end

  ## === Callback GenServer ===

  @impl GenServer
  # Use the name and keeps the list name in the process state so that the handle callbacks can use it.
  def init(name) do
    # This allows us to split the initialization in two phases: one
    # which blocks the client process, and another one which can beperformed after the GenServer.start
    # The to-do list is set to nil because it will be overwritten in handle_continue
    {:ok, {name, nil}, {:continue, :init}}
  end

  # the first callback invoked immediately after init/1
  # The callback receives the provided argument (from the {:continue, some_arg} tuple) 
  # and the server state from the init 
  @impl GenServer
  def handle_continue(:init, {name, nil}) do
    todo_list = Todo.Database.get(name) || Todo.List.new()
    {:noreply, {name, todo_list}}
  end

  @impl true
  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
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

  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {name, todo_list}
    }
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

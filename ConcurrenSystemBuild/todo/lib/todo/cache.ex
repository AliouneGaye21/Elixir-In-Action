defmodule Todo.Cache do
  use GenServer

  def start_link() do
    IO.puts("Starting to-do cache")

    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  defp start_child(todo_list_name) do
    DynamicSupervisor.start_child(
      __MODULE__,
      ## This will lead to Todo.Server.start_link(todo_list_name)
      {Todo.Server, todo_list_name}
    )
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  def server_process(todo_list_name) do
    case start_child(todo_list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid #returned due to the inner working of GenServer registration
    end
  end

  @impl GenServer
  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start_link(todo_list_name)

        {
          :reply,
          new_server,
          Map.put(todo_servers, todo_list_name, new_server)
        }
    end
  end
end

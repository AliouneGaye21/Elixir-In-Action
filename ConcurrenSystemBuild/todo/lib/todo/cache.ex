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

  @doc """
  Poiché il Todo.Cache è un supervisore e puo essere supervisionato a sua volta,
  è necessario implementare il child_spec per poterlo avviare correttamente.
  Questo è necessario per poterlo utilizzare in un albero di supervisione.
  """
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
      # returned due to the inner working of GenServer registration
      {:error, {:already_started, pid}} -> pid
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

defmodule Todo.Cache.LoadTest do
  @num_lists 1_000_000

  def run do
    IO.puts("Starting load test...")

    # CORREZIONE: Avvia direttamente il Todo.Cache invece del Todo.System
    {:ok, cache_pid} = Todo.Cache.start()

    IO.puts("Cache process started at #{inspect(cache_pid)}")
    IO.puts("Testing with #{@num_lists} to-do lists.")

    list_names = for i <- 1..@num_lists, do: "list-#{i}"

    # Misura il tempo per creare 1 milione di server
    {time_to_create, _} =
      :timer.tc(fn ->
        Enum.each(list_names, fn name ->
          Todo.Cache.server_process(cache_pid, name)
        end)
      end)

    avg_creation_time = time_to_create / @num_lists
    IO.puts("Average creation time: #{avg_creation_time} microseconds")

    # Misura il tempo per recuperare i server esistenti
    {time_to_fetch, _} =
      :timer.tc(fn ->
        Enum.each(list_names, fn name ->
          Todo.Cache.server_process(cache_pid, name)
        end)
      end)

    avg_fetch_time = time_to_fetch / @num_lists
    IO.puts("Average fetch time: #{avg_fetch_time} microseconds")
  end
end

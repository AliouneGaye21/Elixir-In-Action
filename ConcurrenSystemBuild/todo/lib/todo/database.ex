defmodule Todo.Database do
  @moduledoc """
  Gestisce un pool di DatabaseWorker e instrada le richieste al worker corretto
  per garantire la sincronizzazione per chiave.
  """
  use GenServer

  @pool_size 3
  @db_folder "./persist"

  # 1. Interfaccia pubblica del server. I client non hanno bisogno di sapere
  # chi sono i worker o come vengono scelti.
  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_args) do
    IO.puts("Starting Database server")
    File.mkdir_p!(@db_folder)
    # 2. Avvia i worker e memorizza i loro PID nello stato del GenServer.
    # Usiamo un map per un accesso più veloce tramite indice.
    workers_map = start_workers()
    {:ok, workers_map}
  end

  # 3. Callback per la gestione delle richieste.
  # La logica di scelta del worker è incapsulata qui.

  @impl GenServer
  def handle_cast({:store, key, data}, workers_map) do
    # La logica di scelta del worker è eseguita all'interno del GenServer.
    worker_pid = choose_worker(key, workers_map)
    Todo.DatabaseWorker.store(worker_pid, key, data)
    # Ritorna il risultato e lo stato (immutato in questo caso).
    {:noreply, workers_map}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, workers_map) do
    # La logica di scelta del worker è incapsulata qui.
    worker_pid = choose_worker(key, workers_map)
    data = Todo.DatabaseWorker.get(worker_pid, key)
    # Risponde al client e ritorna lo stato (immutato in questo caso).
    {:reply, data, workers_map}
  end

  # 4. Funzioni private e helper.

  defp start_workers() do
    # Avvia i worker e li memorizza in un Map per un accesso indicizzato e veloce.
    # Nota: usiamo un range per garantire che gli indici siano da 0 a @pool_size - 1.
    for index <- 0..(@pool_size - 1), into: %{} do
      {:ok, pid} = Todo.DatabaseWorker.start_link(@db_folder)
      {index, pid}
    end
  end

  defp choose_worker(key, workers_map) do
    # :erlang.phash2 calcola un hash e lo normalizza nell'intervallo da 0 a (@pool_size - 1).
    worker_index = :erlang.phash2(key, @pool_size)
    Map.fetch!(workers_map, worker_index)
  end
end

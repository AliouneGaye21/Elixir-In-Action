defmodule Todo.Database do
  @moduledoc """
  Gestisce un pool di DatabaseWorker e instrada le richieste al worker corretto
  per garantire la sincronizzazione per chiave.
  """
  use GenServer

  @pool_size 3
  @db_folder "./persist"

  # L'interfaccia pubblica non cambia per i client
  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)

    # Avvia 3 worker e salva i loro PID nello stato
    workers =
      for _ <- 1..@pool_size do
        {:ok, worker_pid} = Todo.DatabaseWorker.start(@db_folder)
        worker_pid
      end

    {:ok, workers}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, workers) do
    # Sceglie un worker in base alla chiave e inoltra la richiesta
    worker_pid = choose_worker(key, workers)
    Todo.DatabaseWorker.store(worker_pid, key, data)
    {:noreply, workers}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, workers) do
    # Sceglie un worker in base alla chiave e inoltra la richiesta
    worker_pid = choose_worker(key, workers)
    # L'operazione `get` è sincrona, quindi attendiamo la risposta dal worker
    data = Todo.DatabaseWorker.get(worker_pid, key)
    {:reply, data, workers}
  end

  # Funzione privata per selezionare un worker in modo deterministico
  defp choose_worker(key, workers) do
    # :erlang.phash2 calcola un hash e lo normalizza nell'intervallo da 0 a (@pool_size - 1)
    worker_index = :erlang.phash2(key, @pool_size)
    Enum.at(workers, worker_index)
  end
end

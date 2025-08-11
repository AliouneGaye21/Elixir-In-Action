defmodule Todo.Database do
  @moduledoc """
  Gestisce un pool di DatabaseWorker e instrada le richieste al worker corretto
  per garantire la sincronizzazione per chiave.
  """

  # Definisce un attributo del modulo per specificare la dimensione del pool.
  # Questo rende facile modificare il numero di worker in futuro.
  @pool_size 3

  # Questa sezione conteneva la logica per avviare manualmente un supervisore
  # per i worker del database prima dell'integrazione con Poolboy.
  # È stata sostituita dalla funzione `child_spec/1` che utilizza Poolboy.
  #
  # def start_link() do
  #   IO.puts("Starting database server.")
  #   File.mkdir_p!(@db_folder)
  #
  #   children = Enum.map(1..@pool_size, &worker_spec/1)
  #   Supervisor.start_link(children, strategy: :one_for_one)
  # end
  #
  # defp worker_spec(worker_id) do
  #   default_worker_spec = {Todo.DatabaseWorker, {@db_folder, worker_id}}
  #   Supervisor.child_spec(default_worker_spec, id: worker_id)
  # end

  # --- INTERFACCIA PUBBLICA ---

  # Salva un dato in modo distribuito, replicandolo su tutti i nodi del cluster.
  def store(key, data) do
    # Esegue una chiamata di funzione remota (RPC) su più nodi contemporaneamente.
    {_results, bad_nodes} =
      :rpc.multicall(
        # Il modulo da chiamare su ogni nodo (questo stesso modulo).
        __MODULE__,
        # La funzione da eseguire: :store_local per salvare i dati solo sul nodo locale.
        :store_local,
        # Gli argomenti da passare alla funzione.
        [key, data],
        # Un timeout di 5 secondi per prevenire blocchi indefiniti.
        :timer.seconds(5)
      )

    # Se alcuni nodi non hanno risposto in tempo, stampa un avviso.
    Enum.each(bad_nodes, &IO.puts("Store failed on node #{&1}"))
    # Ritorna :ok per indicare che l'operazione è stata avviata.
    :ok
  end

  # Salva un dato sul nodo locale utilizzando il pool di worker.
  def store_local(key, data) do
    # Esegue un'operazione "transazionale" con Poolboy.
    # Poolboy "prende in prestito" un worker dal pool, esegue la funzione
    # e poi lo "restituisce" al pool.
    :poolboy.transaction(
      # Nome del pool da utilizzare (corrisponde al nome di questo modulo).
      __MODULE__,
      # Funzione anonima che riceve il PID di un worker disponibile.
      fn worker_pid ->
        # Utilizza il worker per salvare effettivamente i dati.
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  # Recupera un dato dal nodo locale utilizzando il pool di worker.
  def get(key) do
    # Anche questa è un'operazione transazionale con Poolboy.
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        # Utilizza il worker per recuperare il dato.
        Todo.DatabaseWorker.get(worker_pid, key)
      end
    )
  end

  # Questa funzione veniva usata per scegliere un worker basandosi sull'hash della chiave,
  # garantendo che la stessa chiave venisse sempre gestita dallo stesso worker.
  # Con Poolboy, questa logica non è più necessaria qui, poiché Poolboy gestisce
  # l'assegnazione dei worker.
  #
  # defp choose_worker(key) do
  #   :erlang.phash2(key, @pool_size) + 1
  # end

  # --- SPECIFICA DEL SUPERVISORE ---

  # Definisce come questo modulo deve essere avviato come un child in un albero di supervisione.
  def child_spec(_) do
    # Recupera le impostazioni del database dalla configurazione dell'applicazione.
    db_settings = Application.fetch_env!(:todo, :database)
    db_folder = Keyword.fetch!(db_settings, :db_folder)
    # Assicura che la directory per il database esista.
    File.mkdir_p!(db_folder)

    # Utilizza la funzione di Poolboy per creare una specifica di child.
    # Questo avvierà il processo manager di Poolboy, che a sua volta avvierà i worker.
    :poolboy.child_spec(
      # L'ID del supervisore del pool, che è anche il nome del pool.
      __MODULE__,
      # Opzioni di configurazione per Poolboy.
      [
        # Registra il manager del pool localmente con il nome di questo modulo.
        name: {:local, __MODULE__},
        # Specifica il modulo che ogni worker del pool dovrà eseguire.
        worker_module: Todo.DatabaseWorker,
        # Il numero di worker da avviare.
        size: @pool_size
      ],
      # Argomenti da passare alla funzione `start_link` di ogni `Todo.DatabaseWorker`.
      [db_folder]
    )
  end

  # @impl GenServer
  # def init(_args) do
  #   IO.puts("Starting Database server")
  #   File.mkdir_p!(@db_folder)
  #   # 2. Avvia i worker e memorizza i loro PID nello stato del GenServer.
  #   # Usiamo un map per un accesso più veloce tramite indice.
  #   workers_map = start_workers()
  #   {:ok, workers_map}
  # end

  # # 3. Callback per la gestione delle richieste.
  # # La logica di scelta del worker è incapsulata qui.

  # @impl GenServer
  # def handle_cast({:store, key, data}, workers_map) do
  #   # La logica di scelta del worker è eseguita all'interno del GenServer.
  #   worker_pid = choose_worker(key, workers_map)
  #   Todo.DatabaseWorker.store(worker_pid, key, data)
  #   # Ritorna il risultato e lo stato (immutato in questo caso).
  #   {:noreply, workers_map}
  # end

  # @impl GenServer
  # def handle_call({:get, key}, _from, workers_map) do
  #   # La logica di scelta del worker è incapsulata qui.
  #   worker_pid = choose_worker(key, workers_map)
  #   data = Todo.DatabaseWorker.get(worker_pid, key)
  #   # Risponde al client e ritorna lo stato (immutato in questo caso).
  #   {:reply, data, workers_map}
  # end

  # # 4. Funzioni private e helper.

  # defp start_workers() do
  #   # Avvia i worker e li memorizza in un Map per un accesso indicizzato e veloce.
  #   # Nota: usiamo un range per garantire che gli indici siano da 0 a @pool_size - 1.
  #   for index <- 0..(@pool_size - 1), into: %{} do
  #     {:ok, pid} = Todo.DatabaseWorker.start_link(@db_folder)
  #     {index, pid}
  #   end
  # end

  # defp choose_worker(key, workers_map) do
  #   # :erlang.phash2 calcola un hash e lo normalizza nell'intervallo da 0 a (@pool_size - 1).
  #   worker_index = :erlang.phash2(key, @pool_size)
  #   Map.fetch!(workers_map, worker_index)
  # end
end

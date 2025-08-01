defmodule SimpleRegistry do
  use GenServer

  # Definiamo i nomi delle tabelle come costanti per evitare errori di battitura.
  # Tabella principale per la mappatura `key -> pid`.
  @registry_table :simple_registry_table
  # Tabella ausiliaria per la mappatura `monitor_ref -> key` (per la pulizia). Usiamo una seconda tabella perch'e altrimienti dovremo fare
  # match_bject sull' intera tabella principale per trovare la chiave da cancellare quando un processo monitorato termina.
  #Con complessità O(n) in caso di molti processi registrati, sarebbe inefficiente.
  #Invece, con questa tabella ausiliaria, possiamo trovare la chiave da cancellare in O(1).
  @refs_table :simple_registry_refs_table

  # =================================================
  # API Pubblica (Interfaccia per i client)
  # =================================================

  @doc """
  Avvia il GenServer che funge da PROPRIETARIO delle tabelle ETS.
  Se questo processo termina, le tabelle ETS vengono distrutte automaticamente.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Per evitare race condition, la registrazione deve essere un'operazione atomica
  gestita dal GenServer, che si occupa di inserire in ETS e creare il monitor.
  """
  def register(key) do
    GenServer.call(__MODULE__, {:register, key})
  end

  @doc """
  La ricerca del PID è una LETTURA DIRETTA dalla tabella ETS.
  È estremamente veloce e non coinvolge il GenServer, quindi non crea un bottleneck.
  """
  def whereis(key) do
    case :ets.lookup(@registry_table, key) do
      # :ets.lookup restituisce una lista. Se troviamo l'elemento, estraiamo il pid.
      [{^key, pid}] -> pid
      # Se la lista è vuota, la chiave non esiste.
      [] -> nil
    end
  end

  # =================================================
  # Callbacks del GenServer (Logica interna del server)
  # =================================================

  @impl true
  def init(_opts) do
    # Creiamo le due tabelle ETS all'avvio del server.
    # `:named_table` permette di accedervi tramite il loro nome (un atomo).
    # `:public` permette a qualsiasi processo di leggerle e scriverle.
    # `:read_concurrency` e `:write_concurrency` sono ottimizzazioni per l'accesso concorrente.
    :ets.new(@registry_table, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(@refs_table, [:set, :public, :named_table, read_concurrency: true])

    # Lo stato del GenServer non è importante, le tabelle ETS sono fuori dal suo heap.
    {:ok, nil}
  end

  @impl true
  def handle_call({:register, key}, {caller_pid, _}, state) do
    # `:ets.insert_new` è una funzione atomica: inserisce la tupla solo se la
    # chiave non esiste già. Restituisce `true` in caso di successo, `false` altrimenti.
    if :ets.insert_new(@registry_table, {key, caller_pid}) do
      # Inserimento riuscito! Ora dobbiamo assicurarci di pulire se il processo termina.
      # `Process.monitor` crea un collegamento UNIDIREZIONALE. Se `caller_pid` termina,
      # riceveremo un messaggio `{:DOWN, ...}` senza rischi per il nostro registro.
      ref = Process.monitor(caller_pid)

      # Memorizziamo la relazione `ref -> key` nella seconda tabella.
      # Questo ci servirà per sapere quale chiave cancellare quando riceveremo il messaggio :DOWN.
      :ets.insert(@refs_table, {ref, key})
      {:reply, :ok, state}
    else
      # La chiave era già presente, l'inserimento è fallito.
      {:reply, :error, state}
    end
  end

  @impl true
  # Gestiamo i messaggi `:DOWN` provenienti dai monitor.
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    # Un processo monitorato è terminato. Dobbiamo pulire entrambe le tabelle.
    IO.puts("Processo monitorato terminato. Rimuovo la registrazione.")

    # 1. Usiamo il `ref` per cercare la chiave corrispondente nella tabella dei riferimenti.
    case :ets.lookup(@refs_table, ref) do
      [{^ref, key}] ->
        # 2. Trovata! Usiamo la `key` per cancellare la registrazione dalla tabella principale.
        :ets.delete(@registry_table, key)

        # 3. Cancelliamo anche la voce dalla tabella dei riferimenti, non serve più.
        :ets.delete(@refs_table, ref)
      [] ->
        # Non dovrebbe accadere, ma per sicurezza non facciamo nulla se non troviamo il ref.
        :ok
    end

    {:noreply, state}
  end
end

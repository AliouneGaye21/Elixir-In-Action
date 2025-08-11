defmodule Todo.Server do
  # Imposta la strategia di riavvio del supervisore a `:temporary`.
  # Questo significa che se questo processo `GenServer` termina (normalmente o per un crash),
  # il suo supervisore NON lo riavvierà automaticamente.
  # Verrà riavviato solo su richiesta esplicita (ad esempio, tramite `Todo.Cache`),
  # implementando una logica di "avvio su richiesta".
  use GenServer, restart: :temporary

  ## === API Pubblica ===
  # Questa sezione definisce le funzioni che i client usano per interagire con il server.

  # Avvia il processo GenServer per una specifica to-do list.
  def start_link(name) do
    # Avvia il GenServer e lo registra a livello di cluster con un nome globale.
    GenServer.start_link(__MODULE__, name, name: global_name(name))
  end

  # Funzione helper per costruire la tupla `{:global, ...}` necessaria per
  # la registrazione e la ricerca di processi a livello di cluster.
  defp global_name(name) do
    {:global, {__MODULE__, name}}
  end

  # Cerca il PID di un server to-do registrato globalmente.
  def whereis(name) do
    case :global.whereis_name({__MODULE__, name}) do
      # Se il processo non è registrato, `:global` restituisce `:undefined`.
      :undefined -> nil
      # Altrimenti, restituisce il PID.
      pid -> pid
    end
  end

  # Invia una richiesta asincrona (`cast`) per aggiungere una nuova voce.
  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  # Invia una richiesta sincrona (`call`) per ottenere le voci di una data.
  # Il chiamante attenderà una risposta.
  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  # Invia una richiesta asincrona per aggiornare una voce.
  def update_entry(todo_server, id, updater_fun) do
    GenServer.cast(todo_server, {:update_entry, id, updater_fun})
  end

  # Invia una richiesta asincrona per cancellare una voce.
  def delete_entry(todo_server, id) do
    GenServer.cast(todo_server, {:delete_entry, id})
  end

  ## === Callback del GenServer ===
  # Questa sezione implementa il comportamento specifico di questo GenServer.

  @impl GenServer
  # Callback di inizializzazione (Fase 1).
  # Viene eseguita molto rapidamente per non bloccare il chiamante (il supervisore).
  def init(name) do
    IO.puts("Starting Todo server for #{name}")
    # Lo stato iniziale è `{nome, nil}`. Il `nil` è un segnaposto per la to-do list.
    # La tupla `{:continue, :init}` dice al GenServer di chiamare immediatamente
    # la callback `handle_continue` per completare l'inizializzazione.
    {:ok, {name, nil}, {:continue, :init}}
  end

  # Callback di continuazione dell'inizializzazione (Fase 2).
  # Viene eseguita dopo che `start_link` ha già restituito il PID al chiamante.
  # Ideale per operazioni potenzialmente lente come il caricamento da un database.
  @impl GenServer
  def handle_continue(:init, {name, nil}) do
    # Carica la to-do list dal database o ne crea una nuova se non esiste.
    todo_list = Todo.Database.get(name) || Todo.List.new()

    # Imposta lo stato finale del server e un timeout di inattività.
    # Se il server non riceve messaggi per `expiry_idle_timeout` millisecondi,
    # riceverà un messaggio `:timeout`.
    {:noreply, {name, todo_list}, expiry_idle_timeout()}
  end

  # Callback chiamata quando scatta il timeout di inattività.
  @impl GenServer
  def handle_info(:timeout, {name, todo_list}) do
    IO.puts("Stopping to-do server for #{name}")
    # Ferma il processo GenServer in modo controllato.
    {:stop, :normal, {name, todo_list}}
  end

  # Gestisce la richiesta asincrona di aggiunta di una voce.
  @impl true
  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    # Aggiunge la voce alla struttura dati in memoria.
    new_list = Todo.List.add_entry(todo_list, new_entry)
    # Salva la lista aggiornata nel database.
    Todo.Database.store(name, new_list)
    # Aggiorna lo stato del server e reimposta il timer di inattività.
    {:noreply, {name, new_list}, expiry_idle_timeout()}
  end

  # Gestisce la richiesta asincrona di aggiornamento.
  @impl true
  def handle_cast({:update_entry, id, fun}, state) do
    # NOTA: Questa implementazione aggiorna solo lo stato in memoria,
    # ma non salva le modifiche nel database.
    new_state = Todo.List.update_entry(state, id, fun)
    {:noreply, new_state, expiry_idle_timeout()}
  end

  # Gestisce la richiesta asincrona di cancellazione.
  @impl true
  def handle_cast({:delete_entry, id}, state) do
    # NOTA: Anche questa implementazione non salva le modifiche nel database.
    new_state = Todo.List.delete_entry(state, id)
    {:noreply, new_state, expiry_idle_timeout()}
  end

  # Gestisce la richiesta sincrona per ottenere le voci.
  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {
      # La risposta da inviare al chiamante.
      :reply,
      Todo.List.entries(todo_list, date),
      # Lo stato del server (che non cambia in questa operazione).
      {name, todo_list},
      # Reimposta il timer di inattività.
      expiry_idle_timeout()
    }
  end

  # Funzione helper per recuperare il valore del timeout dalla configurazione.
  defp expiry_idle_timeout(), do: Application.fetch_env!(:todo, :todo_server_expiry)
end


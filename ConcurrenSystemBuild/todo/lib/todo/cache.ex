defmodule Todo.Cache do
  # NOTA: Sebbene questo modulo utilizzi `use GenServer`, la sua funzione principale
  # nell'implementazione corrente è quella di agire come un DynamicSupervisor.
  # Le callback GenServer (`init`, `handle_call`) sono probabilmente residui
  # di una versione precedente e non vengono utilizzate.
  use GenServer

  # Avvia il supervisore dinamico che gestirà i processi Todo.Server.
  def start_link() do
    IO.puts("Starting to-do cache")

    # Avvia un DynamicSupervisor, non un GenServer. Questo supervisore
    # è progettato per avviare processi figli su richiesta (dinamicamente).
    DynamicSupervisor.start_link(
      # Registra il supervisore localmente con il nome di questo modulo.
      name: __MODULE__,
      # Strategia di riavvio: se un figlio crasha, viene riavviato solo quel figlio.
      strategy: :one_for_one
    )
  end

  # --- VECCHIA IMPLEMENTAZIONE (ORA COMMENTATA) ---
  # Questa era la funzione helper per avviare un nuovo child.
  # La sua logica è stata spostata all'interno di `new_process/1`.
  #
  # defp start_child(todo_list_name) do
  #   DynamicSupervisor.start_child(
  #     __MODULE__,
  #     # La tupla {Modulo, arg} è la specifica del child per il DynamicSupervisor.
  #     # Questo avvia Todo.Server.start_link(todo_list_name).
  #     {Todo.Server, todo_list_name}
  #   )
  # end

  # Funzione helper per verificare se un processo server per una data lista esiste già.
  defp existing_process(todo_list_name) do
    # Chiama la funzione `whereis` del server, che probabilmente cerca il processo
    # in un registro (come Registry o :global). Ritorna il pid o nil.
    Todo.Server.whereis(todo_list_name)
  end

  # Funzione helper per avviare un nuovo processo server se non esiste.
  defp new_process(todo_list_name) do
    # Tenta di avviare un nuovo child `Todo.Server` sotto il nostro supervisore dinamico.
    case DynamicSupervisor.start_child(
           __MODULE__,
           {Todo.Server, todo_list_name}
         ) do
      # Caso di successo: il processo è stato avviato, ritorniamo il suo pid.
      {:ok, pid} -> pid
      # Caso di race condition: un altro processo ha avviato il server un istante prima.
      # `start_child` fallisce ma ritorna il pid del processo già esistente.
      # Per noi è un successo, quindi ritorniamo quel pid.
      {:error, {:already_started, pid}} -> pid
    end
  end

  # Specifica come questo modulo (che è un supervisore) debba essere avviato
  # come figlio di un altro supervisore. Questo lo rende un componente componibile
  # all'interno di un albero di supervisione più grande.
  @doc """
  Poiché il Todo.Cache è un supervisore e puo essere supervisionato a sua volta,
  è necessario implementare il child_spec per poterlo avviare correttamente.
  Questo è necessario per poterlo utilizzare in un albero di supervisione.
  """
  def child_spec(_arg) do
    %{
      # ID univoco del child all'interno del supervisore genitore.
      id: __MODULE__,
      # Come avviare questo processo: chiama Todo.Cache.start_link().
      start: {__MODULE__, :start_link, []},
      # Tipo di child: è un supervisore, non un worker.
      type: :supervisor
    }
  end

  # --- CALLBACK GENSERVER (PROBABILMENTE OBSOLETE) ---

  # Callback di inizializzazione per un GenServer. INUTILIZZATA nella logica corrente.
  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  # Funzione pubblica principale: "get or create".
  # Cerca un processo esistente e, se non lo trova, ne crea uno nuovo.
  def server_process(todo_list_name) do
    existing_process(todo_list_name) || new_process(todo_list_name)
  end

  # Callback per gestire chiamate sincrone a un GenServer. INUTILIZZATA nella logica corrente.
  # Questa era la logica di cache quando il modulo era un GenServer che manteneva
  # uno stato con la mappa dei server avviati.
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

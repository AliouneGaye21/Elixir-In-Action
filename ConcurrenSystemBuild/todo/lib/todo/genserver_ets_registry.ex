# defmodule SimpleRegistry do
#   # Usiamo il behaviour GenServer, che ci fornisce un modello standard
#   # per creare processi server che gestiscono uno stato.
#   use GenServer

#   # =================================================
#   # API Pubblica (Interfaccia per i client)
#   # =================================================

#   @doc """
#   Avvia il processo GenServer.
#   Lo registriamo localmente con il nome del modulo (`__MODULE__`) per poterlo
#   chiamare facilmente dalle altre funzioni API senza dover passare il PID in giro.
#   """
#   def start_link() do
#     GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
#   end

#   @doc """
#   Invia una richiesta SINCRONA (`call`) al nostro server per registrare
#   il processo chiamante con una data chiave (`key`).
#   """
#   def register(key) do
#     # Usiamo `call` perché il client ha bisogno di sapere immediatamente
#     # se la registrazione è andata a buon fine (:ok o :error).
#     GenServer.call(__MODULE__, {:register, key})
#   end

#   @doc """
#   Invia una richiesta SINCRONA (`call`) per cercare il PID associato a una chiave.
#   """
#   def whereis(key) do
#     GenServer.call(__MODULE__, {:whereis, key})
#   end

#   # =================================================
#   # Callbacks del GenServer (Logica interna del server)
#   # =================================================

#   @impl true
#   def init(initial_state) do
#     # Questo è il passaggio FONDAMENTALE per la pulizia automatica.
#     # Di default, se un processo A è collegato (link) a un processo B e B termina in modo anomalo,
#     # anche A viene terminato (effetto a catena).
#     # `Process.flag(:trap_exit, true)` cambia questo comportamento: invece di terminare,
#     # il nostro GenServer riceverà un messaggio standard `{:EXIT, from_pid, reason}`
#     # che possiamo gestire tranquillamente in `handle_info`.
#     Process.flag(:trap_exit, true)

#     # Inizializziamo lo stato del server con una mappa vuota.
#     {:ok, initial_state}
#   end

#   @impl true
#   # Gestisce le richieste `call` da `register/1`.
#   # Il secondo argomento, `from`, è una tupla `{caller_pid, tag}` fornita da GenServer.
#   def handle_call({:register, key}, {caller_pid, _}, process_registry) do
#     if Map.has_key?(process_registry, key) do
#       # La chiave è già presente nel registro, quindi la registrazione fallisce.
#       {:reply, :error, process_registry}
#     else
#       # La chiave è libera.
#       # 1. Creiamo un "link" bidirezionale tra il nostro GenServer e il processo chiamante.
#       #    Ora, se `caller_pid` termina, riceveremo un messaggio :EXIT.
#       Process.link(caller_pid)

#       # 2. Aggiungiamo la nuova registrazione allo stato (la mappa).
#       new_registry = Map.put(process_registry, key, caller_pid)

#       # 3. Rispondiamo :ok al client e passiamo il nuovo stato al loop del GenServer.
#       {:reply, :ok, new_registry}
#     end
#   end

#   @impl true
#   # Gestisce le richieste `call` da `whereis/1`.
#   def handle_call({:whereis, key}, _from, process_registry) do
#     # Cerchiamo il PID nella mappa. `Map.get` restituisce il valore o `nil` se non c'è.
#     pid = Map.get(process_registry, key)
#     # Rispondiamo con il risultato e lasciamo lo stato invariato.
#     {:reply, pid, process_registry}
#   end

#   @impl true
#   # Questo callback viene eseguito quando arriva un messaggio che non è una `call` o `cast`.
#   # Grazie a `trap_exit`, la notifica di terminazione di un processo collegato arriva proprio qui!
#   def handle_info({:EXIT, pid, _reason}, process_registry) do
#     IO.puts("Processo #{inspect(pid)} terminato. Rimuovo la registrazione.")

#     # Il nostro compito è trovare e rimuovere la registrazione associata al PID terminato.
#     new_registry = deregister_pid(process_registry, pid)

#     # Indichiamo a GenServer di continuare il loop con il nuovo stato aggiornato.
#     {:noreply, new_registry}
#   end

#   # Funzione helper per rimuovere una registrazione.
#   defp deregister_pid(process_registry, pid) do
#     process_registry
#     # `Enum.reject` crea una nuova lista (di tuple) escludendo l'elemento per cui la funzione anonima
#     # restituisce `true` (ovvero, l'elemento con il PID che vogliamo rimuovere).
#     |> Enum.reject(fn {_key, registered_pid} -> registered_pid == pid end)
#     # Riconvertiamo la lista di tuple in una mappa.
#     |> Enum.into(%{})
#   end
# end

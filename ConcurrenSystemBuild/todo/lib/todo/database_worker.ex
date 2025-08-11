defmodule Todo.DatabaseWorker do
  @moduledoc """
  Un worker GenServer che esegue le operazioni di I/O su disco.
  Non è registrato per nome per permettere l'avvio di multiple istanze.
  """

  # Importa e utilizza i comportamenti standard di un GenServer.
  use GenServer

  # --- INTERFACCIA PUBBLICA ---

  # Funzione per avviare un nuovo processo worker.
  # Richiede la `db_folder` come argomento, che verrà passata alla funzione `init`.
  def start_link(db_folder) do
    GenServer.start_link(
      # Il modulo che implementa le callback del GenServer (questo stesso modulo).
      __MODULE__,
      # L'argomento da passare alla funzione `init`.
      db_folder
    )
  end

  # Funzione client per salvare dati. È una chiamata sincrona (`call`).
  # Il client viene bloccato finché l'operazione non è completata e riceve una risposta.
  def store(pid, key, data) do
    GenServer.call(pid, {:store, key, data})
  end

  # Funzione client per recuperare dati. Anche questa è una chiamata sincrona.
  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  # --- VECCHIA LOGICA DI REGISTRAZIONE (ORA COMMENTATA) ---
  # Questa funzione veniva usata in una versione precedente per creare un "via tuple",
  # un meccanismo per registrare e trovare processi tramite un registro.
  # È stata rimossa perché ora il pool (Poolboy) gestisce direttamente i PID dei worker.
  #
  # defp via_tuple(worker_id) do
  #   Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  # end

  # --- CALLBACK DEL GENSERVER ---

  # Specifica che la funzione `init` è un'implementazione di una callback GenServer.
  # Questo aiuta il compilatore a effettuare controlli di correttezza.
  @impl GenServer
  # Funzione di inizializzazione, chiamata quando il processo worker viene avviato.
  def init(db_folder) do
    IO.puts("Starting database worker.")
    # Lo stato iniziale del processo è semplicemente il percorso della cartella del database.
    # Questo stato verrà passato a tutte le altre callback.
    {:ok, db_folder}
  end

  @impl GenServer
  # Gestisce le richieste sincrone di salvataggio (`:store`).
  def handle_call({:store, key, data}, _, db_folder) do
    db_folder
    # Costruisce il percorso completo del file.
    |> file_name(key)
    # Serializza il termine Elixir in formato binario e lo scrive sul file.
    # `File.write!` solleva un'eccezione in caso di errore.
    |> File.write!(:erlang.term_to_binary(data))

    # Risponde al chiamante con `:ok` e mantiene lo stato (`db_folder`) invariato.
    {:reply, :ok, db_folder}
  end

  @impl GenServer
  # Gestisce le richieste sincrone di recupero (`:get`).
  def handle_call({:get, key}, _from, db_folder) do
    # Tenta di leggere il file.
    data =
      case File.read(file_name(db_folder, key)) do
        # Se la lettura ha successo, deserializza il contenuto da binario a termine Elixir.
        {:ok, contents} ->
          :erlang.binary_to_term(contents)

        # Se il file non esiste (`:enoent`), ritorna `nil`.
        {:error, :enoent} ->
          nil
          # Qualsiasi altro errore di lettura non viene gestito e causerà un crash,
          # seguendo la filosofia "let it crash".
      end

    # Risponde al chiamante con i dati trovati (o `nil`) e mantiene lo stato invariato.
    {:reply, data, db_folder}
  end

  # --- FUNZIONI PRIVATE DI UTILITÀ ---

  # Funzione helper per costruire il percorso completo del file.
  defp file_name(db_folder, key) do
    # Concatena il percorso della cartella e il nome della chiave (convertito in stringa).
    Path.join(db_folder, to_string(key))
  end
end


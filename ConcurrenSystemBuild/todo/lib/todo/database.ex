defmodule Todo.Database do
  @moduledoc """
  Si tratta di un GenServer il cui unico scopo è interagire con il file system.
  Questo centralizza la logica di persistenza e la isola dal resto del sistema.
  """
  use GenServer

  @db_folder "./persist"

  @doc """
  Viene avvviato all'interno dell' init del Todo.Cache. In questo modo il database è 
  pronto a ricevere richieste non appena il sistema principale è attivo. 
  """
  def start do
    # Salvataggio locale del name per evitare di imettere il pid, pero' ci permette di instanziare solo un database process 
    GenServer.start(__MODULE__, nil, name: __MODULE__)
    
  end

  @doc """
  Riceve una chiave (il nome della to-do list) e i dati (la struttura della to-do list). 
  Codifica i dati in formato binario e li scrive su un file il cui nome corrisponde alla chiave. 
  Questa operazione è implementata nel handle_cast 
  """
  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  @doc """
  Riceve una chiave (Il nome della to-do list), legge il file corrispondente, decodifica il contenuto binario e restituisce
  la struttura dati della to-do list. Questa operazione è implementata come un call sincrono 
  => handle_call({:get, key}, _, state)
  """
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_) do
    # Create the specified folder if it doesn't exist
    File.mkdir_p!(@db_folder)
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    spawn(fn ->
      key
      |> file_name()
      |> File.write!(:erlang.term_to_binary(data))
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, caller, state) do
    spawn(fn ->
      data =
        case File.read(file_name(key)) do
          {:ok, contents} -> :erlang.binary_to_term(contents)
          _ -> nil
        end

      GenServer.reply(caller, data)
    end)

    {:noreply, state}
  end

  defp file_name(key) do
    Path.join(@db_folder, to_string(key))
  end
end

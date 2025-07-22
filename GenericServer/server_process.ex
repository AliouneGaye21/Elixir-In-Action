defmodule ServerProcess do
  @moduledoc """
  Un server generico che gestisce richieste sincrone (`call`) e asincrone (`cast`)
  tramite un modulo di callback.
  """

  @doc """
  Avvia un nuovo processo server usando il modulo di callback specificato.

  ## Parametri
    - `callback_module`: Il modulo che implementa le funzioni di callback (`init/0`, `handle_call/2`, `handle_cast/2`).

  ## Ritorna
    - Il PID del processo server avviato.
  """
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  @doc """
  Invia una richiesta sincrona al server e attende la risposta.

  ## Parametri
    - `server_pid`: Il PID del processo server.
    - `request`: La richiesta da inviare.

  ## Ritorna
    - La risposta del server.
  """
  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} ->
        response
    end
  end

  @doc """
  Invia una richiesta asincrona al server (non attende risposta).

  ## Parametri
    - `server_pid`: Il PID del processo server.
    - `request`: La richiesta da inviare.
  """
  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  @doc false
  # Ciclo principale del server: gestisce i messaggi ricevuti.
  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(request, current_state)
        loop(callback_module, new_state)
    end
  end
end

defmodule KeyValueStore do
  @moduledoc """
  Un semplice store chiave/valore basato su ServerProcess.
  """

  @doc """
  Inizializza lo stato del KeyValueStore (una mappa vuota).
  """
  def init do
    %{}
  end

  @doc """
  Avvia un nuovo KeyValueStore come processo server.
  """
  def start do
    ServerProcess.start(KeyValueStore)
  end

  @doc """
  Inserisce una coppia chiave/valore tramite richiesta sincrona.

  ## Parametri
    - `pid`: Il PID del server.
    - `key`: La chiave.
    - `value`: Il valore.

  ## Ritorna
    - `:ok` se l'inserimento è avvenuto con successo.
  """
  def put(pid, key, value) do
    ServerProcess.cast(pid, {:put, key, value})
  end

  @doc """
  Recupera il valore associato a una chiave tramite richiesta sincrona.

  ## Parametri
    - `pid`: Il PID del server.
    - `key`: La chiave.

  ## Ritorna
    - Il valore associato o `nil` se la chiave non esiste.
  """
  def get(pid, key) do
    ServerProcess.call(pid, {:get, key})
  end

  @doc false
  # Gestisce le richieste sincrone di inserimento.
  def handle_call({:put, key, value}, state) do
    {:ok, Map.put(state, key, value)}
  end

  @doc false
  # Gestisce le richieste sincrone di lettura.
  def handle_call({:get, key}, state) do
    {Map.get(state, key), state}
  end

  @doc false
  # Gestisce le richieste asincrone di inserimento.
  def handle_cast({:put, key, value}, state) do
    Map.put(state, key, value)
  end

  @doc """
  Inserisce una coppia chiave/valore tramite richiesta asincrona.

  ## Parametri
    - `pid`: Il PID del server.
    - `key`: La chiave.
    - `value`: Il valore.
  """
  def cast_put(pid, key, value) do
    ServerProcess.cast(pid, {:put, key, value})
  end
end

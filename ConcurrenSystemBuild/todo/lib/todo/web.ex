defmodule Todo.Web do
  # Importa e utilizza le funzionalità di Plug.Router per definire le rotte HTTP.
  use Plug.Router

  # Inserisce il plug :match, che è responsabile di trovare una rotta che corrisponda
  # alla richiesta HTTP in arrivo.
  plug(:match)

  # Inserisce il plug :dispatch, che esegue il codice associato alla rotta trovata
  # dal plug :match.
  plug(:dispatch)

  # Definisce la specifica del child per il supervisore OTP.
  # Questo permette al server web di essere avviato e supervisionato come un processo figlio.
  def child_spec(_arg) do
    # Utilizza Plug.Cowboy per creare la specifica del child per il server HTTP Cowboy.
    Plug.Cowboy.child_spec(
      # Specifica che lo schema da utilizzare è HTTP.
      scheme: :http,
      # Configura le opzioni del server.
      options: [
        # Imposta la porta su cui ascoltare, recuperandola dalla configurazione dell'applicazione.
        # Questo rende la porta configurabile.
        port: Application.fetch_env!(:todo, :http_port)
      ],
      # Indica che questo stesso modulo (Todo.Web) gestirà le richieste in arrivo.
      plug: __MODULE__
    )
  end

  # Definisce un gestore per le richieste POST all'endpoint "/add_entry".
  post "/add_entry" do
    # Estrae i parametri dalla query string dell'URL (es. ?list=...).
    conn = Plug.Conn.fetch_query_params(conn)
    # Recupera i valori "list", "title" e "date" dai parametri.
    # Map.fetch! solleva un errore se una chiave non è presente.
    list_name = Map.fetch!(conn.params, "list")
    title = Map.fetch!(conn.params, "title")
    # Converte la data dal formato stringa ISO 8601 a un struct Date.
    date = Date.from_iso8601!(Map.fetch!(conn.params, "date"))

    # Esegue l'operazione logica:
    list_name
    |> Todo.Cache.server_process()
    # 1. Ottiene il PID del processo server per la to-do list specificata.
    # 2. Invia un messaggio al processo server per aggiungere la nuova voce.
    |> Todo.Server.add_entry(%{title: title, date: date})

    # Prepara e invia la risposta HTTP:
    conn
    # 1. Imposta l'header Content-Type a "text/plain".
    |> Plug.Conn.put_resp_content_type("text/plain")
    # 2. Invia la risposta con status 200 OK e corpo "OK".
    |> Plug.Conn.send_resp(200, "OK")
  end

  # Definisce un gestore per le richieste GET all'endpoint "/entries".
  get "/entries" do
    # Estrae i parametri dalla query string dell'URL.
    conn = Plug.Conn.fetch_query_params(conn)
    # Recupera il nome della lista e la data.
    list_name = Map.fetch!(conn.params, "list")
    date = Date.from_iso8601!(Map.fetch!(conn.params, "date"))

    # Recupera le voci della to-do list:
    entries =
      list_name
      # 1. Ottiene il PID del processo server corretto.
      |> Todo.Cache.server_process()
      # 2. Richiede le voci per la data specificata.
      |> Todo.Server.entries(date)

    # Formatta le voci per la risposta:
    formatted_entries =
      entries
      # 1. Trasforma ogni voce in una stringa formattata "data titolo".
      |> Enum.map(&"#{&1.date} #{&1.title}")
      # 2. Unisce tutte le stringhe in un unico blocco di testo, separate da un a capo.
      |> Enum.join("\n")

    # Invia la risposta HTTP:
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    # Invia la risposta con status 200 OK e le voci formattate come corpo.
    |> Plug.Conn.send_resp(200, formatted_entries)
  end
end

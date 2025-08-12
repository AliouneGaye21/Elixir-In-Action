defmodule Todo.System do
  alias Ecto.Adapters.Postgres
  # Funzione pubblica per avviare l'albero di supervisione del sistema.
  # Viene tipicamente chiamata dal modulo `Todo.Application`.
  def start_link do
    # Avvia un processo supervisore e lo collega al processo chiamante.
    Supervisor.start_link(
      # Lista dei processi figli che questo supervisore deve avviare e monitorare.
      # L'ordine è importante: i figli vengono avviati in sequenza.
      [
        # Il modulo `Todo.Metrics` è attualmente disabilitato.
        # Todo.Metrics,

        # Avvia il supervisore del database (che a sua volta gestisce i worker).
        # Todo.Database,
        # Avvia il supervisore dinamico per le to-do list.
        Todo.Cache,
        # Avvia il server web.
        Todo.Web,

        # Gestione database Postgres
        Todo.Repo
      ],
      # Specifica la strategia di riavvio.
      # :one_for_one significa che se un processo figlio termina,
      # solo quel processo figlio verrà riavviato. Gli altri non saranno influenzati.
      strategy: :one_for_one
    )
  end

  # --- VECCHIA IMPLEMENTAZIONE (ORA COMMENTATA) ---
  # Questa è una modalità alternativa per definire un supervisore,
  # in cui il modulo stesso implementa il behaviour `Supervisor`.
  #
  # # Importa il comportamento e le funzioni del `Supervisor`.
  # use Supervisor
  #
  # # La funzione `start_link` avvia il supervisore usando questo modulo come callback.
  # def start_link do
  #   Supervisor.start_link(__MODULE__, nil)
  # end
  #
  # # La callback `init` definisce i figli e la strategia,
  # # separando la configurazione dalla logica di avvio.
  # def init(_) do
  #   Supervisor.init([Todo.Cache], strategy: :one_for_one)
  # end
end

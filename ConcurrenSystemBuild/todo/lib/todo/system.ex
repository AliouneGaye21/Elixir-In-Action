defmodule Todo.System do
  # Funzione pubblica per avviare l'albero di supervisione del sistema.
  # Viene tipicamente chiamata dal modulo `Todo.Application`.
  def start_link do
    # Definisce la lista dei processi figli da avviare e monitorare.
    children = [
      Todo.Repo,
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies)]},
      Todo.Cache,
      Todo.Web
    ]

    # Definisce le opzioni per il supervisore.
    opts = [strategy: :one_for_one, name: Todo.Supervisor]

    # Avvia il processo supervisore.
    Supervisor.start_link(children, opts)
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

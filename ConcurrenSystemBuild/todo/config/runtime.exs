import Config

http_port =
  if config_env() != :test,
    do: System.get_env("TODO_HTTP_PORT", "5454"),
    else: System.get_env("TODO_TEST_HTTP_PORT", "5455")

config :todo, http_port: String.to_integer(http_port)

# Using a different db_folder in test to avoid polluting the dev db.
db_folder =
  if config_env() != :test,
    do: System.get_env("TODO_DB_FOLDER", "./persist"),
    else: System.get_env("TODO_TEST_DB_FOLDER", "./test_persist")

config :todo, :database, db_folder: db_folder

# Using a shorter to-do server expiry in local dev.
todo_server_expiry =
  if config_env() != :dev,
    do: System.get_env("TODO_SERVER_EXPIRY", "60"),
    else: System.get_env("TODO_SERVER_EXPIRY", "10")

config :todo, todo_server_expiry: :timer.seconds(String.to_integer(todo_server_expiry))

db_hostname = System.get_env("DB_HOSTNAME", "localhost")

config :todo, Todo.Repo,
  adapter: Ecto.Adapters.Postgres,
  # Usa le variabili standard di Postgres
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "todo_dev"),
  # L'hostname è il nome del servizio db
  hostname: db_hostname,
  pool_size: 10

config :todo, ecto_repos: [Todo.Repo]

config :libcluster,
  topologies: [
    # docker_compose_topology: [
    # strategia per Docker
    #   strategy: Cluster.Strategy.DNSPoll,
    #   # Configura il nome dell'app da cercare. Docker Compose usa il nome della cartella.
    #   config: [
    #     # Il nome DNS del servizio da interrogare (dal docker-compose.yml)
    #     query: "app",
    #     # La parte del nome del nodo prima della "@"
    #     node_basename: "todo"
    #   ]
    # ]
    gossip_topology: [
      # Usa la strategia Gossip
      strategy: Cluster.Strategy.Gossip,
      config: [
        # Definiamo il nostro nodo "seed"
        # Tutti gli altri nodi proveranno a connettersi a questo all'avvio.
        seed_nodes: [
          :"todo@app-seed"
        ]
      ]
    ]
  ]

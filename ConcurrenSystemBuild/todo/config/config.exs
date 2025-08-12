import Config

config :todo, Todo.Repo,
  # Adattatore per PostgreSQL
  adapter: Ecto.Adapters.Postgres,
  # È buona norma usare le variabili d'ambiente per le credenziali
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  database: System.get_env("DB_DATABASE", "todo_dev"),
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  # Il pool di connessioni è gestito da Ecto stesso
  pool_size: 10

config :todo, ecto_repos: [Todo.Repo]

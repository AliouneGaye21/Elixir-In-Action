# === STAGE 1: Build ===
# Versioni trovate dall'utente, che corrispondono a un'immagine esistente
ARG ELIXIR="1.18.4"
ARG ERLANG="28.0.1"
ARG DEBIAN="bookworm-20250610-slim"
ARG OS="debian-${DEBIAN}"

# Costruiamo il nome dell'immagine di base
# Corretto il casing di "as" in "AS"
FROM "hexpm/elixir:${ELIXIR}-erlang-${ERLANG}-${OS}" AS builder

WORKDIR /todo
ENV MIX_ENV="prod"

# Installiamo gli strumenti di build
RUN mix local.hex --force && mix local.rebar --force

# Copiamo i file necessari per gestire le dipendenze
COPY mix.exs mix.lock ./
COPY config config

# Scarichiamo solo le dipendenze di produzione
RUN mix deps.get --only prod

# Copiamo il codice sorgente dell'applicazione
COPY lib lib

# Creiamo la release OTP
RUN mix release

# === STAGE 2: Final Image ===
# Partiamo da un'immagine Debian minimale per l'immagine finale
FROM debian:${DEBIAN}

WORKDIR "/todo"

# Installiamo le dipendenze di runtime necessarie, inclusa libncurses6 per iex
RUN apt-get update -y && apt-get install -y openssl locales libncurses6

# Copiamo la release compilata dallo stage 'builder'
COPY \
 --from=builder \
 --chown=nobody:root \
 /todo/_build/prod/rel/todo ./

# Configuriamo le variabili d'ambiente per le locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

# Definiamo il comando di avvio del container
CMD ["/todo/bin/todo", "start_iex"]

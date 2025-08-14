defmodule Todo.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    # 1. Avvia l'albero di supervisione principale tramite il modulo Todo.System
     Todo.System.start_link()
  end
end

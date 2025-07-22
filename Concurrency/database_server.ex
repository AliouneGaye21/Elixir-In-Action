defmodule DatabaseServer do
  @moduledoc
  """
  A simple concurrent database server implementation using Elixir processes.

  This module demonstrates how to spawn a server process that can handle asynchronous queries from clients.
  Clients can send queries to the server and receive results asynchronously.

  ## Functions

  - `start/0`: Starts the database server process.
  - `run_async/2`: Sends a query to the server process asynchronously.
  - `get_result/0`: Waits for the result of a query, with a timeout.
  - `loop/0`: Internal server loop that processes incoming queries.
  - `run_query/1`: Simulates running a database query.

  ## Example
  """

  # Maintain some state ijn the connection
  def start do
    spawn(fn ->
      # Initializes the state during process creation
      connection = :rand.uniform(1000)
      # Enters the loop with that state
      loop(connection)
    end)
  end

  # this function is called by the client and run in the client proceess
  ############### LOGICA LOTO CLIENT######################
  ## This starts the server process
  def start do
    # Spawn a new process that runs the server loop
    spawn(&loop/0)
  end

  ## This sends a query to the server process asynchronously
  def run_async(server_pid, query_def) do
    # Send a message to the server process with the query definition
    # The server will process this message and send the result back to the caller
    send(server_pid, {:run_query, self(), query_def})
  end

  ## This waits for the result of a query, with a timeout
  def get_result do
    # Wait for a message containing the result of the query
    # This function blocks until it receives a message with the query result
    # If no message is received within a certain time, it returns an error
    receive do
      {:query_result, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

  ################## LOGICAL SERVER######################
  # This is the internal server loop that processes incoming queries
  # This function runs in the server process
  # It waits for messages from clients and processes them
  @spec loop() :: no_return()
  defp loop do
    receive do
      ## This is the message pattern that the server expects
      {:run_query, caller, query_def} ->
        ## This simulates running the query
        query_result = run_query(query_def)
        ## This sends the result back to the caller process
        send(caller, {:query_result, query_result})
    end

    loop()
  end

  defp loop(connection) do
    receive do
      {:run_query, from_pid, query_def} ->
        query_result = run_query(connection, query_def)
        send(from_pid, {:query_result, query_result})
    end

    loop(connection)
  end

  ## This simulates running a database query
  defp run_query(query_def) do
    Process.sleep(2000)
    "#{query_def} result"
  end

  defp run_query(connection, query_def) do
    Process.sleep(2000)
    "Connection #{connection}: #{query_def} result"
  end
end

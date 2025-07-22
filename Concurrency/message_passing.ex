defmodule MessagePassing do
  @doc """
  Creates a function that simulates running a query.
  The function takes a query definition and simulates a delay before returning the result.
  This simulates a long-running operation, such as a database query.
  The result is a string indicating the query result.
  """
  def run_query() do
    fn query_def ->
      Process.sleep(2000)
      "#{query_def} result"
    end
  end

  @doc """
  Creates an asynchronous query function that spawns a new process to run the query.
  The result of the query is sent back to the caller process.
  """
  def async_query() do
    # This is the function that simulates running a query.
    run_query = run_query()

    fn query_def ->
      # Get the current process ID
      caller = self()
      # Spawn a new process to run the query

      spawn(fn ->
        # Run the query
        query_result = run_query.(query_def)
        # Send the result back to the caller process
        send(caller, {:query_result, query_result})
      end)
    end
  end

  @doc """
  Waits for a message containing the result of a query.
  This function blocks until it receives a message with the query result.
  It returns the result contained in the message.
  """
  def get_result() do
    receive do
      # Return the result from the message
      {:query_result, result} -> result
    end
  end

  @doc """
  Runs a series of asynchronous queries and collects their results.
  """
  def run() do
    # Get the asynchronous query function
    async_query = async_query()
    # Spawn queries asynchronously
    Enum.each(1..5, &async_query.("query #{&1}"))
    # Collect results from the messages
    Enum.map(1..5, fn _ -> get_result() end)
  end
end

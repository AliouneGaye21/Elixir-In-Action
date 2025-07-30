defmodule MyAgent do
  use GenServer

  @moduledoc """
  A simple agent that can be used to store and retrieve state.
  The state is initialized with a function passed to `start_link/1`.
  The basic idea is to encapsulate state management in a GenServer,
  allowing for concurrent access and updates.
  """

  @doc """
  Starts the agent with an initial state defined by the `init_fun` function.
  The `init_fun` should return the initial state of the agent.
  """
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(init_fun) do
    GenServer.start_link(__MODULE__, init_fun)
  end

  @doc """
  Initializes the agent with the state returned by `init_fun`.
  This function is called when the agent is started.
  """
  @impl GenServer
  def init(init_fun) do
    {:ok, init_fun.()}
  end

  @doc """
  Retrieves the current state of the agent.
  This function is a synchronous call that blocks until the state is returned.
  """
  def get(pid, fun) do
    GenServer.call(pid, {:get, fun})
  end

  @doc """
  Updates the state of the agent using the provided function `fun`.
  The function `fun` receives the current state and returns the new state.
  This function is a synchronous call that blocks until the state is updated.
  """
  def update(pid, fun) do
    GenServer.call(pid, {:update, fun})
  end

  @doc """
  Handles synchronous calls to the agent.
  It matches on the `:get` and `:update` messages to retrieve or update
  the state, respectively.
  """
  @impl GenServer
  def handle_call({:get, fun}, _from, state) do
    response = fun.(state)
    # Return the result of the function applied to the state
    {:reply, response, state}
  end

  @impl GenServer
  def handle_call({:update, fun}, _from, state) do
    new_state = fun.(state)
    # Return :ok after updating the state
    {:reply, :ok, new_state}
  end
end

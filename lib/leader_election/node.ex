defmodule LeaderElection.NodeState do
  defstruct id: nil,
            port: nil,
            leader_id: nil,
            is_leader: false,
            # All nodes know each other's addresses and ports
            nodes: [1, 2, 3, 4, 5],
            time_ms: 2000,
            election_timer: nil,
            ping_timer: nil,
            leader_timeout_timer: nil
end

defmodule LeaderElection.Node do
  use GenServer
  import LeaderElection.HelperFunctions
  import LeaderElection.MessageHandler
  import LeaderElection.Network
  import LeaderElection.Timer

  def child_spec(node_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [node_id]}
    }
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: __MODULE__)
  end

  @impl GenServer
  def init(id) do
    port = 5000 + id
    state = %LeaderElection.NodeState{id: id, port: port}

    IO.puts("Node started on port #{state.port}")

    Task.start_link(fn -> listen(state.port) end)

    # Newly started nodes initiate the leader selection procedure immediately after starting
    send(self(), :start_election)

    {:ok, state}
  end

  #### GenServer process messages handlers

  @impl GenServer
  def handle_info(:start_election, state) do
    IO.puts("Starting election...")

    state =
      state
      |> cancel_timer(:election_timer)
      |> cancel_timer(:ping_timer)
      |> cancel_timer(:leader_timeout_timer)

    more_senior_nodes = get_more_senior_nodes(state)

    if length(more_senior_nodes) === 0 do
      IO.puts("I'm the most senior node, declaring myself as leader")
      send(self(), :declare_leadership)
    else
      # The node that started the election sends an ALIVE? message to all nodes more senior than itself
      broadcast_message(more_senior_nodes, "ALIVE? #{state.id}")

      # If the election_timer is not cancelled within time_ms, this node will declare itself as leader using election_timeout_reached process
      timer = Process.send_after(self(), :election_timeout_reached, state.time_ms)
      state = state |> Map.put(:election_timer, timer) |> Map.put(:is_leader, false)
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:election_timeout_reached, state) do
    IO.puts("No FINETHANKS received. I am the new leader.")
    send(self(), :declare_leadership)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:declare_leadership, state) do
    other_nodes = Enum.filter(state.nodes, fn node -> node != state.id end)
    broadcast_message(other_nodes, "IMTHEKING #{state.id}")
    state = state |> Map.put(:leader_id, state.id) |> Map.put(:is_leader, true)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:send_ping_to_leader, state) do
    if !state.is_leader and state.leader_id != nil do
      send_message(state.leader_id, "PING #{state.id}")
    end

    state = reset_ping_timer(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:leader_timeout, state) do
    IO.puts(
      "Leader #{state.leader_id} did not respond within 4xT interval. It is considered dead."
    )

    send(self(), :start_election)
    {:noreply, state}
  end

  #### TCP messages cast and handlerss

  @impl GenServer
  def handle_cast({:handle_network_message, msg}, state) do
    # IO.puts("Received message: #{msg}")

    [message, sender_id_str] = msg |> String.trim() |> String.split(" ")
    sender_id = String.to_integer(sender_id_str)
    new_state = handle_message(message, sender_id, state)
    {:noreply, new_state}
  end
end

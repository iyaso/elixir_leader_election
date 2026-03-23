defmodule LeaderElection.MessageHandler do
  import LeaderElection.HelperFunctions
  import LeaderElection.Network
  import LeaderElection.Timer

  def handle_message("ALIVE?", sender_id, state) do
    IO.puts("Received ALIVE? from #{sender_id}")

    send_message(sender_id, "FINETHANKS #{state.id}")

    more_senior_nodes = get_more_senior_nodes(state)

    if length(more_senior_nodes) === 0 do
      IO.puts("I'm the most senior node, declaring myself as leader")
      send(self(), :declare_leadership)
    else
      send(self(), :start_election)
    end

    state
  end

  def handle_message("FINETHANKS", sender_id, state) do
    IO.puts("Received FINETHANKS from #{sender_id}")
    cancel_timer(state, :election_timer)
  end

  def handle_message("IMTHEKING", sender_id, state) do
    IO.puts("Received IMTHEKING from #{sender_id}. Accepting #{sender_id} as a leader.")

    state
    |> cancel_timer(:election_timer)
    |> Map.put(:leader_id, sender_id)
    |> Map.put(:is_leader, false)
    |> reset_ping_timer()
    |> reset_leader_timeout()
  end

  def handle_message("PING", sender_id, state) do
    # IO.puts("Received PING from #{sender_id}")
    if state.is_leader do
      send_message(sender_id, "YES_THE_LEADER_HERE #{state.id}")
    end

    state
  end

  def handle_message("YES_THE_LEADER_HERE", _sender_id, state) do
    # IO.puts("Received YES_THE_LEADER_HERE from #{sender_id}")
    reset_leader_timeout(state)
  end

  def handle_message(unknown_message, sender_id, state) do
    IO.puts("Received unknown message: #{unknown_message} from #{sender_id}")
    state
  end
end

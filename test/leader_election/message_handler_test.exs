defmodule LeaderElection.MessageHandlerTest do
  use ExUnit.Case
  alias LeaderElection.MessageHandler

  setup do
    state = %{
      id: 2,
      nodes: [1, 2, 3],
      is_leader: false,
      leader_id: nil,
      ping_timer: nil,
      leader_timeout_timer: nil,
      election_timer: nil,
      time_ms: 1000
    }

    {:ok, state: state}
  end

  describe "handle_message with ALIVE?" do
    test "when more senior nodes exist, it starts an election", %{state: state} do
      # There's still 3 more senior than current 2, so it should start election
      MessageHandler.handle_message("ALIVE?", 1, state)

      # start_election should be sent
      assert_receive :start_election
    end

    test "when no more senior nodes exist, it declares leadership", %{state: state} do
      # Most senior node
      senior_state = %{state | id: 3}
      MessageHandler.handle_message("ALIVE?", 1, senior_state)

      # declare_leadership should be sent
      assert_receive :declare_leadership
    end
  end

  describe "handle_message with IMTHEKING" do
    test "it updates the leader_id and reset timers", %{state: state} do
      new_state = MessageHandler.handle_message("IMTHEKING", 3, state)

      assert new_state.leader_id == 3
      assert new_state.is_leader == false

      # Timers should be reset
      assert new_state.ping_timer != nil
      assert new_state.leader_timeout_timer != nil
    end
  end

  describe "handle_message with PING" do
    test "it does nothing if not leader", %{state: state} do
      MessageHandler.handle_message("PING", 1, state)

      # Should NOT receive anything since it doesn't respond if not leader
      refute_receive _
    end

    test "it sends a response if leader", %{state: state} do
      leader_state = %{state | is_leader: true}
      MessageHandler.handle_message("PING", 1, leader_state)
      # future plan is to mock LeaderElection.Network.send_message
    end
  end

  describe "handle_message with FINETHANKS" do
    test "it cancels the election timer", %{state: state} do
      # Dummy timer
      timer = Process.send_after(self(), :dummy, 1000)
      state_with_timer = %{state | election_timer: timer}

      # FINETHANKS should cancel election_timer immediately
      new_state = MessageHandler.handle_message("FINETHANKS", 3, state_with_timer)

      assert new_state.election_timer == nil
      # timer is cancelled
      assert Process.read_timer(timer) == false
    end
  end
end

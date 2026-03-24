defmodule LeaderElection.TimerTest do
  use ExUnit.Case
  alias LeaderElection.Timer

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

  describe "cancel_timer" do
    test "it cancels the timer", %{state: state} do
      # Dummy timer
      timer = Process.send_after(self(), :dummy, 1000)
      state_with_timer = %{state | ping_timer: timer}

      # cancel_timer should cancel the timer
      new_state = Timer.cancel_timer(state_with_timer, :ping_timer)

      assert new_state.ping_timer == nil
      assert Process.read_timer(timer) == false
    end
  end

  describe "reset_ping_timer" do
    test "it resets the ping timer", %{state: state} do
      old_timer = Process.send_after(self(), :dummy, 1000)
      state_with_timer = %{state | ping_timer: old_timer}

      new_state = Timer.reset_ping_timer(state_with_timer)

      # Verify the old timer was cancelled
      assert Process.read_timer(old_timer) == false

      new_timer = new_state.ping_timer
      # Verify there is a new timer reference in the state
      assert new_timer != nil
      assert new_timer != old_timer

      # Verify the new timer is actually active (returns time remaining)
      assert is_integer(Process.read_timer(new_timer))
    end
  end

  describe "reset_leader_timeout" do
    test "it resets the leader timeout timer", %{state: state} do
      old_timer = Process.send_after(self(), :dummy, 1000)
      state_with_timer = %{state | leader_timeout_timer: old_timer}

      new_state = Timer.reset_leader_timeout(state_with_timer)

      # Verify the old timer was cancelled
      assert Process.read_timer(old_timer) == false

      new_timer = new_state.leader_timeout_timer
      # Verify there is a new timer reference in the state
      assert new_timer != nil
      assert new_timer != old_timer

      # Verify the new timer is actually active (returns time remaining)
      assert is_integer(Process.read_timer(new_timer))
    end
  end
end

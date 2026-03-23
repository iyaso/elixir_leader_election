defmodule LeaderElection.Timer do
  def cancel_timer(state, timer_key) do
    timer = Map.get(state, timer_key)

    if timer != nil do
      Process.cancel_timer(timer)
    end

    Map.put(state, timer_key, nil)
  end

  def reset_ping_timer(state) do
    state = cancel_timer(state, :ping_timer)
    # Once every T seconds, each node sends a PING message to the leader
    timer = Process.send_after(self(), :send_ping_to_leader, state.time_ms)
    Map.put(state, :ping_timer, timer)
  end

  def reset_leader_timeout(state) do
    state = cancel_timer(state, :leader_timeout_timer)
    # If the leader does not respond within the 4×T interval, he is considered retired
    timer = Process.send_after(self(), :leader_timeout, state.time_ms * 4)
    Map.put(state, :leader_timeout_timer, timer)
  end
end

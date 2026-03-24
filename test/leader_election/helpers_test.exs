defmodule LeaderElection.HelperFunctionsTest do
  use ExUnit.Case
  alias LeaderElection.HelperFunctions

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

  describe "get_more_senior_nodes" do
    test "returns more senior node one", %{state: state} do
      nodes = HelperFunctions.get_more_senior_nodes(state)
      assert nodes == [3]
    end

    test "returns more senior nodes many", %{state: state} do
      state = %{state | id: 1}
      nodes = HelperFunctions.get_more_senior_nodes(state)
      assert nodes == [2, 3]
    end
  end
end

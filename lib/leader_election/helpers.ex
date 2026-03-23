defmodule LeaderElection.HelperFunctions do
  def get_more_senior_nodes(state) do
    Enum.filter(state.nodes, fn node_id -> node_id > state.id end)
  end
end

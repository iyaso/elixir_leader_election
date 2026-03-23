defmodule NodeState do
  defstruct id: nil,
            port: nil,
            leader_id: nil,
            is_leader: false,
            nodes: [1, 2, 3, 4, 5], # All nodes know each other's addresses and ports
            time_ms: 2000,
            election_timer: nil,
            ping_timer: nil,
            leader_timeout_timer: nil
end

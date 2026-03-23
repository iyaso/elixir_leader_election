defmodule LeaderElection do
  use Application
  import Server

  def start(_type, _args) do
    args = System.argv()

    if length(args) != 1 do
      IO.puts("Usage: mix run -- <node_id>")
      System.halt(1)
    end

    node_id = args |> Enum.at(0) |> String.to_integer()

    start_node(node_id)

    Process.sleep(:infinity)
  end
end

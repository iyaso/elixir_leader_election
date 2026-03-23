defmodule LeaderElection do
  use Application

  def start(_type, _args) do
    args = System.argv()

    if length(args) != 1 do
      IO.puts("Usage: mix run -- <node_id>")
      System.halt(1)
    end

    node_id = args |> Enum.at(0) |> String.to_integer()

    children = [
      {Task.Supervisor, name: LeaderElection.TaskSupervisor},
      {LeaderElection.Node, node_id}
    ]

    opts = [strategy: :one_for_one, name: LeaderElection.Supervisor]
    Supervisor.start_link(children, opts)

    Process.sleep(:infinity)
  end
end

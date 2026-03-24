defmodule LeaderElection.Network do
  @moduledoc """
  Network setup logic and communication between nodes.
  """

  def listen(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    accept_loop(socket)
  end

  def accept_loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Task.Supervisor.start_child(LeaderElection.TaskSupervisor, fn ->
      handle_client(client)
    end)

    accept_loop(socket)
  end

  defp handle_client(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        GenServer.call(LeaderElection.Node, {:handle_network_message, String.trim(data)})

      _ ->
        :ok
    end

    :gen_tcp.close(client)
  end

  def send_message(to_id, msg) do
    port = 5000 + to_id

    case :gen_tcp.connect(~c"localhost", port, [:binary, packet: :line, active: false], 500) do
      {:ok, socket} ->
        :gen_tcp.send(socket, msg <> "\n")
        :gen_tcp.close(socket)

      {:error, _reason} ->
        :ok
    end
  end

  def broadcast_message(ids, msg) do
    Enum.each(ids, fn target_id ->
      if target_id != nil do
        send_message(target_id, msg)
      end
    end)
  end
end

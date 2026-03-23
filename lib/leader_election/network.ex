defmodule Network do
  def accept_loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    # Spawn a new process to receive and cast the messages
    spawn(fn ->
      case :gen_tcp.recv(client, 0) do
        {:ok, data} ->
          msg = String.trim(data)
          GenServer.cast(Server, {:handle_network_message, msg})

        _ ->
          :ok
      end

      :gen_tcp.close(client)
    end)

    accept_loop(socket)
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

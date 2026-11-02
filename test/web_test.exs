defmodule WebTest do
  use ExUnit.Case, async: true

  # The listener is bound before the server task starts, so a client can never
  # dial a port nobody is listening on yet.
  defp listen do
    listener = Socket.Web.listen!(0)
    {_ip, port} = Socket.Web.local!(listener)
    {listener, port}
  end

  # Runs `body` with the accepted, handshaken server side of the connection.
  defp serve(listener, body) do
    Task.start_link(fn ->
      client = Socket.Web.accept!(listener)
      Socket.Web.accept!(client)
      body.(client)
    end)
  end

  describe "passive mode" do
    test "a binary frame survives the round trip" do
      {listener, port} = listen()
      serve(listener, fn client -> Socket.Web.send!(client, Socket.Web.recv!(client)) end)

      socket = Socket.Web.connect!("localhost", port)
      Socket.Web.send!(socket, {:binary, <<0, 1, 254, 255>>})

      assert Socket.Web.recv!(socket) == {:binary, <<0, 1, 254, 255>>}
    end

    test "a frame sent with mask: false is sent unmasked" do
      {listener, port} = listen()

      serve(listener, fn client ->
        Socket.Web.send!(client, {:text, "from the server"}, mask: false)
      end)

      socket = Socket.Web.connect!("localhost", port)

      assert Socket.Web.recv!(socket) == {:text, "from the server"}
    end

    test "a fragmented message arrives frame by frame" do
      {listener, port} = listen()

      serve(listener, fn client ->
        Socket.Web.send!(client, {:fragmented, :text, "a"})
        Socket.Web.send!(client, {:fragmented, :continuation, "b"})
        Socket.Web.send!(client, {:fragmented, :end, "c"})
      end)

      socket = Socket.Web.connect!("localhost", port)

      assert Socket.Web.recv!(socket) == {:fragmented, :text, "a"}
      assert Socket.Web.recv!(socket) == {:fragmented, :continuation, "b"}
      assert Socket.Web.recv!(socket) == {:fragmented, :end, "c"}
    end

    test "a close code the application chose is reported, not raised" do
      {listener, port} = listen()
      serve(listener, fn client -> Socket.Web.close(client, {4000, "bye"}, wait: false) end)

      socket = Socket.Web.connect!("localhost", port)

      assert Socket.Web.recv!(socket) == {:close, 4000, "bye"}
    end

    test "a registered close code still arrives as its name" do
      {listener, port} = listen()
      serve(listener, fn client -> Socket.Web.close(client, :going_away, wait: false) end)

      socket = Socket.Web.connect!("localhost", port)

      assert Socket.Web.recv!(socket) == {:close, :going_away, ""}
    end
  end
end

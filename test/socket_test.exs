defmodule SocketTest do
  use ExUnit.Case

  test "connect" do
    Task.start_link(fn -> server(12_345) end)

    socket = Socket.Web.connect!("localhost", 12_345)
    socket |> Socket.Web.send!({:text, "test"})
    assert socket |> Socket.Web.recv!() == {:text, "test"}
  end

  # test "connect tls" do
  #   socket = Socket.Web.connect!("echo.websocket.org", secure: true)
  #   socket |> Socket.Web.send!({:text, "test"})
  #   assert socket |> Socket.Web.recv!() == {:text, "test"}
  # end

  test "connect path" do
    Task.start_link(fn -> server(12_346) end)
    socket = Socket.Web.connect!("localhost", 12_346, path: "/websocket")
    socket |> Socket.Web.send!({:text, "test"})
    assert socket |> Socket.Web.recv!() == {:text, "test"}
  end

  test "connect ping" do
    Task.start_link(fn -> server(1234) end)

    socket = Socket.Web.connect!("localhost", 1234)
    socket |> Socket.Web.send!({:ping, "test"})
    assert socket |> Socket.Web.recv!() == {:pong, "test"}
  end

  test "accept reports a Socket.Error as a message" do
    listener = Socket.Web.listen!(0)

    assert {:error, message} = Socket.Web.accept(listener, timeout: 50)
    assert is_binary(message)
  end

  def server(port) do
    server = Socket.Web.listen!(port)
    client = server |> Socket.Web.accept!()

    # here you can verify if you want to accept the request or not, call
    # `Socket.Web.close!` if you don't want to accept it, or else call
    # `Socket.Web.accept!`
    client |> Socket.Web.accept!()

    server_loop(client)
  end

  def server_loop(client) do
    # echo the  message
    case client |> Socket.Web.recv!() do
      {:ping, msg} ->
        client |> Socket.Web.send!({:pong, msg})

      msg ->
        client |> Socket.Web.send!(msg)
    end

    server_loop(client)
  end
end

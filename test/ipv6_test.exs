defmodule Socket.IPv6Test do
  use ExUnit.Case

  @v6 {0, 0, 0, 0, 0, 0, 0, 1}

  test "an IPv6reference parses as the address it names" do
    assert Socket.Address.parse("[::1]") == @v6
    assert Socket.Address.parse("::1") == @v6
    assert Socket.Address.valid?("[2001:db8::1]")
    # Only a v6 address is written inside brackets, and the brackets must close.
    assert Socket.Address.parse("[127.0.0.1]") == nil
    assert Socket.Address.parse("[::1") == nil
    assert Socket.Address.parse("[::1]x") == nil
    assert Socket.Address.parse("example.com") == nil
  end

  test "TCP reaches an IPv6 literal given as a string, a reference or a tuple" do
    listener = Socket.TCP.listen!(0, local: [address: @v6], version: 6)
    {_ip, port} = Socket.local!(listener)

    assert {:ok, from_string} = Socket.TCP.connect("::1", port, timeout: 1_000)
    assert {:ok, from_reference} = Socket.TCP.connect("[::1]", port, timeout: 1_000)
    assert {:ok, from_tuple} = Socket.TCP.connect(@v6, port, timeout: 1_000)

    Socket.close(from_string)
    Socket.close(from_reference)
    Socket.close(from_tuple)
    Socket.close(listener)
  end

  test "SSL sends an IPv6 literal to the socket, not to the resolver" do
    # No TLS server answers here, so the handshake cannot succeed. What the test
    # reads is the failure: :nxdomain means the literal went to the resolver.
    listener = Socket.TCP.listen!(0, local: [address: @v6], version: 6)
    {_ip, port} = Socket.local!(listener)

    assert {:error, reason} = Socket.SSL.connect("::1", port, timeout: 500)
    refute reason == :nxdomain

    Socket.close(listener)
  end
end

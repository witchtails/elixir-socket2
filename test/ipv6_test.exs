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
end

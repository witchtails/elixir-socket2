defmodule Socket.ErrorTest do
  use ExUnit.Case, async: true

  describe "exception/1" do
    test "formats known TCP errors" do
      error = Socket.Error.exception(reason: :econnrefused)
      assert error.message == "connection refused"
    end

    test "formats TLS alert tuples without raising" do
      alert =
        {:tls_alert,
         {:handshake_failure,
          ~c"TLS client: In state wait_cert_cr generated CLIENT ALERT: Fatal - Handshake Failure"}}

      error = Socket.Error.exception(reason: alert)

      assert error.message ==
               "TLS client: In state wait_cert_cr generated CLIENT ALERT: Fatal - Handshake Failure"
    end

    test "raise with TLS alert produces Socket.Error" do
      alert = {:tls_alert, {:unknown_ca, ~c"TLS alert: unknown CA"}}

      assert_raise Socket.Error, "TLS alert: unknown CA", fn ->
        raise Socket.Error, reason: alert
      end
    end

    test "falls back to inspect for other reasons" do
      error = Socket.Error.exception(reason: {:nxdomain, :extra})
      assert error.message == "{:nxdomain, :extra}"
    end

    test "formats unknown atoms as strings" do
      error = Socket.Error.exception(reason: :some_unknown_reason)
      assert is_binary(error.message)
      assert error.message =~ "some_unknown_reason"
    end
  end
end

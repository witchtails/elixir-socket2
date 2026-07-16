Elixir sockets made decent ![Build](https://github.com/dominicletz/elixir-socket2/actions/workflows/test.yml/badge.svg)
==========================
This library wraps `gen_tcp`, `gen_udp` and `gen_sctp`, `ssl` and implements
websockets and socks.

Sockets2 is a fork from the zombie project at: https://github.com/meh/elixir-socket updated for OTP20+ and with PRs from other forks merged. 


Installation
--------
In your `mix.exs` file

```elixir
defp deps do
  [
    # ...
    {:socket2, "~> 2.1.2"},
    # ...
  ]
end
```

Then run `mix deps.get` to install

Examples
--------

```elixir
defmodule HTTP do
  def get(uri) when is_binary(uri) or is_list(uri) do
    get(URI.parse(uri))
  end

  def get(%URI{host: host, port: port, path: path}) do
    sock = Socket.TCP.connect!(host, port, packet: :line)
    sock |> Socket.Stream.send!("GET #{path || "/"} HTTP/1.1\r\nHost: #{host}\r\n\r\n")

    [_, code, text] = Regex.run(~r"HTTP/1.1 (.*?) (.*?)\s*$", sock |> Socket.Stream.recv!())

    headers = headers([], sock) |> Enum.into(%{})

    sock |> Socket.packet!(:raw)
    body = sock |> Socket.Stream.recv!(String.to_integer(headers["Content-Length"]))

    {{String.to_integer(code), text}, headers, body}
  end

  defp headers(acc, sock) do
    case sock |> Socket.Stream.recv!() do
      "\r\n" ->
        acc

      line ->
        [_, name, value] = Regex.run(~r/^(.*?):\s*(.*?)\s*$/, line)

        headers([{name, value} | acc], sock)
    end
  end
end
```
SSL
----------
### Client

You will need to generate certificates to make it work. Here are some command lines using openssl

```bash
$ mkdir certs
$ cd certs
$ openssl genpkey -algorithm RSA -out key.pem -pkeyopt rsa_keygen_bits:4096
$ openssl req -new -x509 -key key.pem -out cert.pem -days 1000 -sha384
```

Then here is a simple example of connecting to an SSL server.

```elixir
    ipaddr = {1, 2, 3, 5}
    port = 5061
    ssl_options = [
      cert: [path: "certs/certificate.pem"],
      key: [ path: "certs/private_key.pem" ],
      verify: false, # Deactivate cert verification
      versions: [:"tlsv1.2"], # Force TLS 1.2
      ciphers: [~c"AES256-GCM-SHA384"] # Add secure cipher
    ]
    sock = Socket.SSL.connect!(ipaddr, port, ssl_options)
    Socket.Stream.send(sock, "Hello World!")
```

Websockets
----------

### Client

```elixir
socket = Socket.Web.connect!("echo.websocket.org")
socket |> Socket.Web.send!({ :text, "test" })
socket |> Socket.Web.recv!() # => {:text, "test"}
```

In order to connect to a TLS websocket, use the `secure: true` option:

```elixir
socket = Socket.Web.connect!("echo.websocket.org", secure: true)
```

The `connect!` function also accepts other parameters, most notably the `path` parameter, which is used when the websocket server endpoint exists on a path below the domain ie. "example.com/websocket":

```elixir
socket = Socket.Web.connect!("example.com", path: "/websocket")
```

Note that websocket servers send ping messages. A pong reply from your client tells the server to keep the connection open and to send more data. If your client doesn't send a pong reply then the server will close the connection. Here's an example of how to get get both the data you want and reply to a server's pings:

```elixir
socket = Socket.Web.connect!("echo.websocket.org")
case socket |> Socket.Web.recv!() do
  {:text, data} ->
    # process data
  {:ping, _ } ->
    socket |> Socket.Web.send!({:pong, ""})
end
```

### Server

```elixir
server = Socket.Web.listen!(80)
client = server |> Socket.Web.accept!()

# here you can verify if you want to accept the request or not, call
# `Socket.Web.close!` if you don't want to accept it, or else call
# `Socket.Web.accept!`
client |> Socket.Web.accept!()

# echo the first message
client |> Socket.Web.send!(client |> Socket.Web.recv!())
```

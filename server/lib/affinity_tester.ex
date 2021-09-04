defmodule AffinityTester do
  use GenServer

  def start_link([]) do
    port = System.fetch_env!("PORT") |> String.to_integer
    my_pod_name = System.fetch_env!("MY_POD_NAME")
    GenServer.start_link(__MODULE__, [my_pod_name, port])
  end

  def init([my_pod_name, port]) do
    {:ok, sock} = :gen_udp.open(port, [mode: :binary, active: true])
    {:ok, %{sock: sock, my_pod_name: my_pod_name}}
  end

  def handle_info({:udp, sock, refl_ip, refl_port, payl}, 
                  state = %{sock: sock, my_pod_name: my_pod_name}) do
    case response(payl, refl_ip, refl_port, my_pod_name) do
      {:ok, resp} -> :ok = :gen_udp.send(sock, refl_ip, refl_port, resp)
      _error -> :nop
    end
    {:noreply, state}
  end

  def response(<<"maartensmagic", binterm :: binary>>, ip, port, my_pod_name) do
    %{id: id, seq: seq} = :erlang.binary_to_term(binterm)
    x_address = xor_mapped_address(id, ip, port)
    resp = :erlang.term_to_binary(%{seq: seq, x_address: x_address, pod_name: my_pod_name})
    {:ok, "maartensmagic" <> resp}
  end
  def response(_, _ip, _port, _state) do
    {:error, :magic_is_gone}
  end

  # Loosely after section 10.2.12 of the STUN standard.  Used to give the
  # client an indicator of its reflective IP and PORT as seen from the server.
  # XORing the reflective IP and PORT with a sequence number protects against
  # NAT'ing devices on-route back to the client fiddling with the reflective IP
  # and PORT.
  def xor_mapped_address(id, {ip1, ip2, ip3, ip4}, port) do
    <<id_upper :: 16, _ :: 16>> = <<id::32>>
    x_port = Bitwise.bxor(id_upper, port)
    <<ip :: 32>> = <<ip1::8, ip2::8, ip3::8, ip4::8>>
    x_ip = Bitwise.bxor(id, ip)
    <<x_address :: 48>> = <<x_ip :: 32, x_port :: 16>>
    x_address
  end

end

defmodule Trike.Util do
  def format_socket(sock) do
    with {:ok, {local_ip, local_port}} <- :inet.sockname(sock),
         {:ok, {peer_ip, peer_port}} <- :inet.peername(sock) do
      "{#{format_ip(local_ip, local_port)} -> #{format_ip(peer_ip, peer_port)}}"
    else
      unexpected -> inspect(unexpected)
    end
  end

  def format_ip({a, b, c, d}, port) do
    "#{a}.#{b}.#{c}.#{d}:#{port}"
  end
end

defmodule TodoBackendWeb.Plugs.CorsPlug do
  @moduledoc """
  A simple CORS plug to handle cross-origin requests.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("Access-Control-Allow-Origin", "*")
    |> put_resp_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("Access-Control-Allow-Headers", "Content-Type, Accept, Authorization")
    |> put_resp_header("Access-Control-Allow-Credentials", "true")
    |> handle_options_request()
  end

  defp handle_options_request(%Plug.Conn{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(200, "")
    |> halt()
  end

  defp handle_options_request(conn), do: conn
end

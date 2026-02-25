defmodule TodoBackendWeb.PageController do
  use TodoBackendWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

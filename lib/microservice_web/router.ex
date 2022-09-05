defmodule MicroserviceWeb.Router do
  use Plug.Router
  if Mix.env == :dev do
    use Plug.Debugger
  end
  use Plug.ErrorHandler

  import Plug.Conn
  alias MicroserviceWeb.{Controller, Renderer}

  plug Plug.Logger
  plug Plug.Parsers, 
    parsers: [:urlencoded, :json], 
    pass: ["text/*"], 
    json_decoder: Jason
  plug :match
  plug :dispatch

  get "/", do: conn |> Renderer.render_html("index.html")

  get "/subscribers" do
    Controller.Subscribers.index(conn, conn.params)
  end
  post "/subscribers" do
    Controller.Subscribers.create(conn, conn.params)
  end
  get "/subscribers/confirm/:token" do
    Controller.Subscribers.confirm(conn, conn.params)
  end

  if Mix.env == :dev do
    forward "/emails", to: Bamboo.SentEmailViewerPlug
  end

  match _ do
    conn |> send_resp(:not_found, "Not Found!")
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn |> send_resp(:internal_server_error, "Something went wrong")
  end

end
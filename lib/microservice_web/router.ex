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

  get "/subscriptions" do
    Controller.Subscriptions.index(conn, conn.params)
  end
  post "/subscriptions" do
    Controller.Subscriptions.create(conn, conn.params)
  end
  get "/subscriptions/confirm/:token" do
    Controller.Subscriptions.confirm(conn, conn.params)
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
defmodule MicroserviceWeb.Router do
  use Plug.Router
  if Mix.env == :dev do
    use Plug.Debugger
  end
  use Plug.ErrorHandler

  import Plug.Conn

  alias MicroserviceWeb.Controllers.Subscriptions

  plug Plug.Logger
  plug Plug.Parsers, 
    parsers: [:urlencoded, :json], 
    pass: ["text/*"], 
    json_decoder: Jason
  plug :match
  plug :dispatch

  get "/health_check", do: conn |> send_resp(:ok, "Up!")

  get  "/subscriptions", do: Subscriptions.index(conn)
  post "/subscriptions", do: Subscriptions.create(conn)
  post "/subscriptions/confirm/:token", do: Subscriptions.confirm(conn)

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

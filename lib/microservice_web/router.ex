defmodule MicroserviceWeb.Router do
  use Plug.Router
  if Mix.env == :dev do
    use Plug.Debugger
  end
  use Plug.ErrorHandler

  import Plug.Conn

  alias Microservice.Newsletter
  alias MicroserviceWeb.{Errors, Renderer}

  plug Plug.Logger
  plug Plug.Parsers, 
    parsers: [:urlencoded, :json], 
    pass: ["text/*"], 
    json_decoder: Jason
  plug :match
  plug :dispatch

  get "/health_check", do: conn |> send_resp(:ok, "Up!")

  get "/", do: conn |> Renderer.render_html("index.html")

  get "/subscriptions" do
    subscriptions = Newsletter.get_confirmed_subscriptions()
    conn |> Renderer.render_json(%{ 
      count: length(subscriptions),
      subscriptions: subscriptions 
    })
  end
  
  post "/subscriptions" do
    case Newsletter.create_subscription(conn.params) do
      # Subscriber created
      {:ok, subscription} -> 
        conn 
        |> put_status(:created)
        |> Renderer.render_json(%{ subscription: subscription })
      # Failed to create subscriber
      {:error, changeset} ->
        # Render the error json
        errors = Ecto.Changeset.traverse_errors(changeset, &Errors.translate_error/1)
        conn 
        |> put_status(:bad_request)
        |> Renderer.render_json(errors)
    end
  end

  get "/subscriptions/confirm/:token" do
    case Newsletter.confirm_subscription(token) do
      {:ok, subscription} -> conn |> Renderer.render_json(%{ subscription: subscription })
      {:error, :invalid} -> conn |> put_status(:conflict) |> Renderer.render_json(%{ error: "Invalid confirmation token" })
      {:error, :expired} -> conn |> put_status(:conflict) |> Renderer.render_json(%{ error: "Confirmation token has expired" })
    end
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

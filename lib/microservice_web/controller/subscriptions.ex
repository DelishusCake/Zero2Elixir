defmodule MicroserviceWeb.Controllers.Subscriptions do
  import Plug.Conn

  alias Microservice.Newsletter
  alias MicroserviceWeb.{Errors, Renderer}

  def index(conn) do
    subscriptions = Newsletter.get_confirmed_subscriptions()
    conn |> Renderer.render_json(%{ 
      count: length(subscriptions),
      subscriptions: subscriptions 
    })
  end
  
  def create(conn) do
    case Newsletter.create_subscription(conn.params) do
      # Subscriber created
      {:ok, subscription} -> 
        conn 
        |> put_status(:created)
        |> Renderer.render_json(%{ subscription: subscription })
      # Failed to create subscriber
      {:error, changeset} ->
        # Render the error json
        conn 
        |> put_status(:bad_request)
        |> render_errors(changeset)
    end
  end

  def confirm(conn) do
    %{ token: token } = conn.params
    case Newsletter.confirm_subscription(token) do
      {:ok, subscription} -> conn |> Renderer.render_json(%{ subscription: subscription })
      {:error, :invalid} -> conn |> put_status(:conflict) |> Renderer.render_json(%{ error: "Invalid confirmation token" })
      {:error, :expired} -> conn |> put_status(:conflict) |> Renderer.render_json(%{ error: "Confirmation token has expired" })
    end
  end

  defp render_errors(conn, %Ecto.Changeset{} = changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, &Errors.translate_error/1)
    conn |> Renderer.render_json(errors)
  end
end
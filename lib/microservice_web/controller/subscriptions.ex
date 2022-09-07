defmodule MicroserviceWeb.Controller.Subscriptions do
  alias Microservice.{Newsletter, }
  alias MicroserviceWeb.{Renderer, Errors}

  import Plug.Conn

  def index(conn, _params) do
    subscriptions = Newsletter.get_confirmed_subscriptions()
    conn |> Renderer.render_json(subscriptions)
  end

  def create(conn, params) do
    case Newsletter.create_subscription(params) do
      # Subscriber created
      {:ok, subscription} -> 
        conn 
        |> put_status(:created)
        |> Renderer.render_json(subscription)
      # Failed to create subscriber
      {:error, changeset} ->
        # Render the error json
        errors = Ecto.Changeset.traverse_errors(changeset, &Errors.translate_error/1)
        conn 
        |> put_status(:bad_request)
        |> Renderer.render_json(errors)
    end
  end

  def confirm(conn, %{ "token" => token } = _params) do
    case Newsletter.confirm_subscription(token) do
      {:ok, subscription} -> conn |> Renderer.render_json(subscription)
      {:error, :invalid} -> conn |> Renderer.render_json(%{ error: "Invalid confirmation token" })
      {:error, :expired} -> conn |> Renderer.render_json(%{ error: "Confirmation token has expired" })
    end
  end

end
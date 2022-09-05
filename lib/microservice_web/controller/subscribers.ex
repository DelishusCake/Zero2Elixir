defmodule MicroserviceWeb.Controller.Subscribers do
  alias Microservice.{Newsletter, Mailer}
  alias MicroserviceWeb.{Email, Renderer, Errors}

  import Plug.Conn

  def index(conn, _params) do
    people = Newsletter.get_confirmed_subscribers()
    conn |> Renderer.render_json(people)
  end

  def create(conn, params) do
    case Newsletter.create_subscription(params) do
      {:ok, subscription} -> 
        # Generate a confirmation token
        token = Newsletter.generate_confirm_token(subscription)
        # Send the confirmation email
        Email.subscription_confirm(subscription.email, token) 
        |> Mailer.deliver_later()
        # Render the response
        conn 
        |> put_status(:created)
        |> Renderer.render_json(subscription)
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
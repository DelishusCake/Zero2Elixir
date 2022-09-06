defmodule Microservice.Newsletter do
  alias Microservice.{Repo, Email, Mailer}
  alias Microservice.Newsletter.Subscription

  import Ecto.Query

  @max_token_age (60*10) # 10 minutes

  def get_subscribers() do
    Subscription |> Repo.all()
  end

  def get_confirmed_subscribers() do
    query = from sub in Subscription,
      where: not is_nil(sub.confirmed_at) 
    query |> Repo.all()
  end

  def create_subscription(attrs \\ %{}) do
    Repo.transaction(fn ->
      # Insert the new subscriber
      case create_new_subscription(attrs) do
        {:ok, subscription} -> 
          # Send the confirmation email
          case send_confirm_email(subscription) do
            {:ok, _} -> subscription
            {:error, _email} -> Repo.rollback(:failed_to_send)
          end
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def confirm_subscription(token) do
    # Get the secret key to verify the token with
    secret = get_secret_key_base()
    # Verify the token
    with {:ok, id} <- Plug.Crypto.verify(secret, "confirm subscription", token, max_age: @max_token_age) do
      # Get the subscription to confirm
      subscription = Repo.get!(Subscription, id)
      # Get the confirmed at value for the subscription, or the current UTC timestamp
      # NOTE: This prevents already confirmed subscriptions from being affected again
      confirmed_at = (subscription.confirmed_at || get_now())
      # Map the subscription to a changeset and update the repo
      subscription
      |> Subscription.changeset_confirm(%{ confirmed_at: confirmed_at })
      |> Repo.update()
    else
      err -> err
    end
  end

  defp create_new_subscription(attrs) do
    %Subscription{} 
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  defp send_confirm_email(%Subscription{ id: id } = subscription) do
    # Get the secret key to sign the token with
    secret = get_secret_key_base()
    # Sign a new confirmation token that expires in 10 minutes
    token = Plug.Crypto.sign(secret, "confirm subscription", id, max_age: @max_token_age)
    # Render and send the email
    Email.subscription_confirm(subscription.email, subscription.name, token) 
    |> Mailer.deliver_later()
  end

  defp get_secret_key_base(), do: Application.get_env(:microservice, :secret_key_base, 8080) || raise "Secret key base not defined"

  defp get_now(), do: DateTime.utc_now() |> DateTime.truncate(:second)
end

defmodule Microservice.Newsletter do
  alias Microservice.{Repo, Email, Mailer}
  alias Microservice.Newsletter.Subscription

  import Ecto.Query

  @max_token_age (60*10) # 10 minutes

  @doc """
  Get all subscriptions, both confirmed and unconfirmed
  """
  def get_subscriptions() do
    Subscription |> Repo.all()
  end

  @doc """
  Get all confirmed subscriptions
  """
  def get_confirmed_subscriptions() do
    query = from sub in Subscription,
      where: not is_nil(sub.confirmed_at) 
    query |> Repo.all()
  end

  @doc """
  Create a new subscription and send them an email with instructions 
  on how to confirm their subscription
  """
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

  @doc """
  Given a confirmation token, either verify the bearer's email or return an error
  """
  def confirm_subscription(token) do
    # Verify the token
    with {:ok, id} <- verify_subscription_token(token) 
    do
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

  @doc """
  Check that a confirmation token is valid
  """
  def verify_subscription_token(token) do
    # Get the secret key to verify the token with
    secret = get_secret_key_base()
    # Verify the token
    Plug.Crypto.verify(secret, "confirm subscription", token, max_age: @max_token_age)
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

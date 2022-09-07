defmodule Microservice.Newsletter do
  alias Microservice.{Repo, Email, Mailer, Token}
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
    # Insert the new subscriber and send the confirmation email
    with  {:ok, subscription} <- new_subscription(attrs) |> Repo.insert(),
          {:ok, _email} = confirmation_email(subscription) |> Mailer.deliver_later()
    do
      {:ok, subscription}
    end
  end

  @doc """
  Given a confirmation token, either verify the bearer's email or return an error
  """
  def confirm_subscription(token) do
    # Verify the token
    with {:ok, id} <- Token.verify("confirm subscription", token, max_age: @max_token_age)
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
    end
  end

  defp new_subscription(attrs), do: %Subscription{} |> Subscription.changeset(attrs)

  defp confirmation_email(%Subscription{ id: id } = subscription) do
    # Sign a new confirmation token that expires in 10 minutes
    token = Token.sign("confirm subscription", id, max_age: @max_token_age)
    # Render and send the email
    Email.subscription_confirm(subscription.email, subscription.name, token)
  end

  defp get_now(), do: DateTime.utc_now() |> DateTime.truncate(:second)
end

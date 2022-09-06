defmodule Microservice.Newsletter.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  # Allow JSON encoding of the name and email fields
  @derive {Jason.Encoder, only: [:name, :email]}
  # Describe the Ecto schema
  schema "subscriptions" do
    field :name, :string
    field :email, :string
    # Will be null until confirmed
    field :confirmed_at, :utc_datetime
    timestamps()
  end

  @doc """
  Creation changeset, validates names and emails
  """ 
  def changeset(subscription, attrs \\ %{}) do
    subscription 
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> validate_name()
    |> validate_email()
  end

  @doc """
  Confirmation changeset, validates confirmed_at
  """
  def changeset_confirm(subscription, attrs) do 
    subscription
    |> cast(attrs, [:confirmed_at])
    |> validate_required(:confirmed_at)
  end

  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, max: 256)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, max: 256)
    |> unsafe_validate_unique(:email, Microservice.Repo)
    |> unique_constraint(:email)
  end
end

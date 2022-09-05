defmodule Microservice.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :name,  :string, null: false
      add :email, :string, null: false
      add :confirmed_at, :utc_datetime
      timestamps()
    end
    create index(:subscriptions, [:email], unique: true)
    create index(:subscriptions, [:confirmed_at], where: "confirmed_at IS NOT NULL")
  end
end

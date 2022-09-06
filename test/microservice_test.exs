defmodule MicroserviceTest do
  use ExUnit.Case
  use Microservice.RepoCase
  doctest Microservice

  alias Microservice.Newsletter

  describe "newsletter" do
    alias Newsletter.Subscription
    
    test "create_subscription/1 works with valid data" do
      attrs = %{ name: "Test", email: "test@test.com" }

      assert {:ok, %Subscription{} = subscription} = Newsletter.create_subscription(attrs)
      assert subscription.name == "Test"
      assert subscription.email == "test@test.com"   
    end

    test "create_subscription/1 blocks mulitple subscriptions with the same email" do
      attrs = %{ name: "Test", email: "test@test.com" }

      assert {:ok, %Subscription{} = subscription} = Newsletter.create_subscription(attrs)
      assert subscription.name == "Test"
      assert subscription.email == "test@test.com"

      assert {:error, %Ecto.Changeset{ errors: errors } = _changeset} = Newsletter.create_subscription(attrs)
      assert errors[:email] 
    end

    test "create_subscription/1 blocks invalid emails" do
      attrs = %{ name: "Test", email: "test" }

      assert {:error, %Ecto.Changeset{ errors: errors } = _changeset} = Newsletter.create_subscription(attrs)
      assert errors[:email] 
    end
  end

end

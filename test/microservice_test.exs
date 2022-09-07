defmodule MicroserviceTest do
  use ExUnit.Case
  use Bamboo.Test
  use Microservice.RepoCase

  alias Microservice.Newsletter

  @link_regex ~r/http:\/\/localhost:8000\/subscriptions\/confirm\/(?<token>[a-zA-Z0-9._-]+)\s?/

  doctest Microservice

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

      {:error, %Ecto.Changeset{ errors: errors } = _changeset} = Newsletter.create_subscription(attrs)
      assert errors[:email] 
    end

    test "create_subscription/1 blocks invalid emails" do
      attrs = %{ name: "Test", email: "test" }

      assert {:error, %Ecto.Changeset{ errors: errors } = _changeset} = Newsletter.create_subscription(attrs)
      assert errors[:email] 
    end

    test "create_subscription/1 sends confirmation email" do
      attrs = %{ name: "Test", email: "test@test.com" }

      assert {:ok, %Subscription{ id: id, email: email } = _sub} = Newsletter.create_subscription(attrs)
      
      assert_delivered_email_matches(%{to: [{_, ^email}], text_body: text_body})
      assert %{ "token" => token } = Regex.named_captures(@link_regex, text_body)
    end

    test "confirm_subscription/1 can confirm subscriptions" do
      attrs = %{ name: "Test", email: "test@test.com" }

      assert {:ok, %Subscription{ email: email } = _sub} = Newsletter.create_subscription(attrs)
      
      assert_delivered_email_matches(%{to: [{_, ^email}], text_body: text_body})
      assert %{ "token" => token } = Regex.named_captures(@link_regex, text_body)

      assert {:ok, _sub} = Newsletter.confirm_subscription(token)
    end
  end

end

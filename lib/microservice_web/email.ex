defmodule MicroserviceWeb.Email do
  import Bamboo.Email

  def subscription_confirm(to, token) do
    new_email(
      to: to,
      from: "noreply@test.com",
      subject: "Please confirm your email",
      html_body: "Please visit http://localhost:8000/subscribers/confirm/"<>token,
      text_body: "Please visit http://localhost:8000/subscribers/confirm/"<>token)
  end
end
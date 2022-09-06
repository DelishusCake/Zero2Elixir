defmodule Microservice.Email do
  import Bamboo.Email

  alias MicroserviceWeb.Renderer

  @from "noreply@test.com"

  def subscription_confirm(to, name, token) do
    link = "http://localhost:8000/subscribers/confirm/" <> token 
    new_email(
      to: to,
      from: @from,
      subject: "Welcome, "<>name<>"!",
      html_body: Renderer.render_template("welcome_email.html", [name: name, link: link]),
      text_body: Renderer.render_template("welcome_email.txt", [name: name, link: link]))
  end
end
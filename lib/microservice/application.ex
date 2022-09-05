defmodule Microservice.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Microservice.Worker.start_link(arg)
      # {Microservice.Worker, arg}
      Microservice.Repo,
      {Plug.Cowboy, scheme: :http, plug: MicroserviceWeb.Router, options: [port: get_port()]}
    ]

    Logger.info("Starting application...")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Microservice.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_port, do: Application.get_env(:microservice, :port, 8080)
end

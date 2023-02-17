defmodule ChatbotFb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
        {Plug.Cowboy,scheme: :http,plug: ChatbotFb.ChatRouter, options: [port: 8080]}
    ]
    # :observer.start()
    opts = [strategy: :one_for_one, name: ChatbotFb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

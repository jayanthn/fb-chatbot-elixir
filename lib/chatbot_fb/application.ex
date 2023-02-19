defmodule ChatbotFb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    {:ok,port} = Application.get_env(:chatbot_fb,:port)
    children = [
        {Plug.Cowboy,scheme: :http, plug: ChatbotFb.ChatRouter, options: [port: port]}
    ]

    # :observer.start()
    opts = [strategy: :one_for_one, name: ChatbotFb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

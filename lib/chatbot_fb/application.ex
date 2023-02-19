defmodule ChatbotFb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    name = Application.get_application(__MODULE__)
    dbg(name)
    env = Application.get_all_env(__MODULE__)
    dbg(env)
    # {:ok,port} = Application.get_env(:chatbot_fb,:port)

    children = [
        {Plug.Cowboy,scheme: :http, plug: ChatbotFb.ChatRouter, options: [port: 4000]}
    ]

    # :observer.start()
    opts = [strategy: :one_for_one, name: ChatbotFb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule ChatbotFb.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatbot_fb,
      version: "0.1.0",
      elixir: "~> 1.14",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger,:observer],
      mod: {ChatbotFb.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.6.0"},
      {:poison, "~> 5.0"},
    ]
  end
end

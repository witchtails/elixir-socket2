defmodule Socket.MixProject do
  use Mix.Project

  def project do
    [
      app: :socket2,
      elixir: "~> 1.12",
      version: "2.1.3",
      deps: deps(),
      package: package(),
      description: "Socket handling library for Elixir, updated for OTP20+ by the witchtails team"
    ]
  end

  # Configuration for the OTP application
  def application do
    [extra_applications: [:crypto, :ssl, :logger]]
  end

  defp deps do
    [
      {:certifi, "~> 2.12"},
      {:ex_doc, "~> 0.30", only: [:dev]},
      {:credo, "~> 1.7", only: [:dev]}
    ]
  end

  defp package do
    [
      name: :socket2,
      maintainers: ["dominicletz"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/witchtails/elixir-socket2"}
    ]
  end
end

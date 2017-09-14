defmodule GraphqlDeux.Mixfile do
  use Mix.Project

  def project do
    [
      app: :graphql_deux,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.0"},
      {:exjsx, "~> 4.0"},
      {:graphql, github: "shopgun/graphql-erlang"}
    ]
  end
end

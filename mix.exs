defmodule WorkerPool.Mixfile do
  use Mix.Project

  def project do
    [app: :workerpool,
     version: "0.0.1",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :sqlex, :exsouth],
     mod: {WorkerPool, []}]
  end

  defp deps do
    [
      {:sqlex, github: "SkAZi/sqlex"},
      {:exsouth, github: "SkAZi/exsouth"}
    ]
  end
end

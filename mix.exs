defmodule Cogctl.Mixfile do
  use Mix.Project

  def project do
    [app: :cogctl,
     version: "0.2.0",
     elixir: "~> 1.2",
     elixirc_options: [warnings_as_errors: System.get_env("ALLOW_WARNINGS") == nil],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     escript: escript,
     aliases: aliases,
     elixirc_paths: elixirc_paths(Mix.env)]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:getopt, github: "jcomellas/getopt", tag: "v0.8.2"},
      {:ibrowse, "~> 4.2.2"},
      {:httpotion, "~> 2.1.0"},
      {:configparser_ex, "~> 0.2.0"},
      {:cog_api, github: "operable/cog-api-client", ref: "3aa6f44aaf3b105c52064eebe38222fa861816aa"},
    ]
  end

  defp escript do
    [main_module: Cogctl,
     name: "cogctl",
     app: :cogctl,
     emu_args: "-noshell"]
  end

  defp aliases do
    ["escript": ["deps.get", "deps.compile", "escript.build"]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end

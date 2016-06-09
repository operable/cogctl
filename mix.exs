defmodule Cogctl.Mixfile do
  use Mix.Project

  def project do
    [app: :cogctl,
     version: "0.7.5",
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
    [applications: [:logger, :yaml_elixir]]
  end

  defp deps do
    [
      # We override here because of a conflict in rebar. Spanner brings in emqtt which includes
      # rebar as a dep.
      {:getopt, github: "operable/getopt", override: true},
      # ExVCR is pointing to the github repo for ibrowse for some reason, so we'll just
      # override it here for now.
      {:ibrowse, "~> 4.2.2", override: true},
      {:httpotion, "~> 2.1.0"},
      # We override poison here because spanner is set to 1.5.2 due to phoenix requirements
      {:poison, "~> 2.0", override: true},
      {:configparser_ex, "~> 0.2.0"},
      {:cog_api, github: "operable/cog-api-client", branch: "v0.7.5"},
      {:spanner, github: "operable/spanner", branch: "v0.7.5"},
      {:exvcr, "~> 0.7.3", only: [:dev, :test]}
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

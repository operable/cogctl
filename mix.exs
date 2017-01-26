defmodule Cogctl.Mixfile do
  use Mix.Project

  def project do
    [app: :cogctl,
     version: "0.18.0",
     elixir: "~> 1.3.1",
     elixirc_options: [warnings_as_errors: System.get_env("ALLOW_WARNINGS") == nil],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     escript: escript,
     aliases: aliases,
     elixirc_paths: elixirc_paths(Mix.env)]
  end

  def application do
    [applications: [:cog_api, :logger, :yaml_elixir]]
  end

  defp deps do
    [
      # Operable code
      ########################################################################
      {:cog_api, github: "operable/cog-api-client", branch: "v1.0.0-beta.2"},
      {:spanner, github: "operable/spanner", branch: "v1.0.0-beta.2"},

      {:configparser_ex, github: "operable/configparser_ex", branch: "vanstee/disable-comments"},
      # We override here because of a conflict in rebar. Spanner
      # brings in emqtt which includes rebar as a dep.
      {:getopt, github: "operable/getopt", override: true},
      {:httpotion, "~> 3.0"},
      {:uuid, "~> 1.1.5"},

      # Testing
      ########################################################################
      {:exvcr, "~> 0.8", only: [:dev, :test]}
    ]
  end

  defp escript do
    [main_module: Cogctl,
     name: "cogctl",
     app: :cogctl,
     emu_args: "-noshell"]
  end

  defp aliases do
    ["escript": ["deps.get", "deps.compile", "escript.build"],
     "escript-dev": ["deps.compile", "escript.build"]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end

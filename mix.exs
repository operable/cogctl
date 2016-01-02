defmodule Cogctl.Mixfile do
  use Mix.Project

  def project do
    [app: :cogctl,
     version: "0.0.1",
     elixir: "~> 1.1",
     elixirc_options: [warnings_as_errors: System.get_env("ALLOW_WARNINGS") == nil],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     compilers: [:elixir, :app],
     escript: escript,
     aliases: aliases]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:getopt, github: "jcomellas/getopt", tag: "v0.8.2"},
     {:ibrowse, "~> 4.2.2"},
     {:poison, "~> 1.5.0"},
     {:httpotion, "~> 2.1.0"},
     {:configparser_ex, "~> 0.2.0"}]
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

end

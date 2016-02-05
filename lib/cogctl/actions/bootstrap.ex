defmodule Cogctl.Actions.Bootstrap do

  use Cogctl.Action, "bootstrap"
  alias Cogctl.CogApi

  def option_spec() do
    [{:status, ?s, 'status', :undefined, 'Queries Cog\'s current bootstrap status'}]
  end

  def run(options, _args, config, profile) do
    client = CogApi.new_client(profile)
    case :proplists.get_value(:status, options) do
      :undefined ->
        do_bootstrap(client, config)
      _ ->
        do_query(client)
    end
  end

  defp do_query(client) do
    case CogApi.bootstrap_show(client) do
      {:ok, body} ->
        status = case body do
          %{"bootstrap" => %{"bootstrap_status" => true}} ->
            "Bootstrapped"
          _ ->
            "Not bootstrapped"
        end

        display_output("Status: #{status}")
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_bootstrap(client, config) do
    case CogApi.bootstrap_create(client) do
      {:ok, admin} ->
        values = config.values
                 |> Map.put(client.host, %{"user" => get_in(admin, ["bootstrap", "username"]),
                                           "password" => get_in(admin, ["bootstrap", "password"]),
                                           "host" => client.host,
                                           "port" => client.port,
                                           "secure" => false})
        config = %{config | dirty: true, values: values}
        Cogctl.Config.save(config)
        display_output("Bootstrapped")
      {:error, %{"bootstrap" => %{"error" => error}}} ->
        display_error(error)
      {:error, %{"error" => error}} ->
        display_error(error)
    end
  end

end

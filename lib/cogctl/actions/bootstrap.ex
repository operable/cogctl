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
    {:ok, body} = CogApi.is_bootstrapped?(client)
    status = if get_in(body, ["bootstrap", "bootstrap_status"]) == true do
      "Bootstrapped"
    else
      "Not bootstrapped"
    end

    display_output("Status: #{status}")
  end

  defp do_bootstrap(client, config) do
    case CogApi.bootstrap(client) do
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
      {:error, error} ->
        display_error(get_in(error, ["bootstrap", "error"]))
    end
  end

end

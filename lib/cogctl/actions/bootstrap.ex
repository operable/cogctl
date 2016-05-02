defmodule Cogctl.Actions.Bootstrap do

  use Cogctl.Action, "bootstrap"

  def option_spec() do
    [{:status, ?s, 'status', :undefined, 'Queries Cog\'s current bootstrap status'}]
  end

  def run(options, _args, config, endpoint) do
    case :proplists.get_value(:status, options) do
      :undefined ->
        do_bootstrap(endpoint, config)
      _ ->
        do_query(endpoint)
    end
  end

  defp do_query(endpoint) do
    case CogApi.HTTP.Internal.bootstrap_show(endpoint) do
      {:ok, body} ->
        status = case body do
          %{"bootstrap" => %{"bootstrap_status" => true}} ->
            "Bootstrapped"
          _ ->
            "Not bootstrapped"
        end

        display_output("Status: #{status}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_bootstrap(endpoint, config) do
    case CogApi.HTTP.Internal.bootstrap_create(endpoint, status_code: true) do
      {200, admin} ->
        values = config.values
                 |> Map.put(endpoint.host, %{"user" => get_in(admin, ["bootstrap", "username"]),
                                           "password" => get_in(admin, ["bootstrap", "password"]),
                                           "host" => endpoint.host,
                                           "port" => endpoint.port,
                                           "secure" => false})
        config = %{config | dirty: true, values: values}
        Cogctl.Config.save(config)
        display_output("Bootstrapped")
      {423, _} ->
        display_output("Already bootstrapped")
      {_, %{"errors" => error}} ->
        display_error(error)
    end
  end

end

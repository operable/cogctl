defmodule Cogctl.Actions.Permissions.Create do
  use Cogctl.Action, "permissions create"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Permission name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_create(client, options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_create(client, options) do
    params = make_permission_params(options)
    case CogApi.permission_create(client, %{permission: params}) do
      {:ok, _resp} ->
        IO.puts("Created #{params[:name]}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp make_permission_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end

defmodule Cogctl.ActionUtil do
  def convert_to_params(options, whitelist) do
    params = Keyword.take(options, Keyword.keys(whitelist))

    # Check if any required params are undefined
    invalid = Enum.any?(params, fn
      {key, :undefined} ->
        case Keyword.get(whitelist, key, :optional) do
          :required ->
            true
          :optional ->
            false
        end
      _ ->
        false
    end)

    case invalid do
      true ->
        :error
      false ->
        params = params
                  |> Enum.reject(&match?({_, :undefined}, &1))
                  |> Enum.into(%{})

        {:ok, params}
    end
  end

  def display_output(output) do
    IO.puts(output)
    :ok
  end

  def display_error(error) do
    IO.puts(:stderr, "ERROR: #{error}")
    :error
  end

  def display_arguments_error do
    display_error("Missing required arguments")
  end
end

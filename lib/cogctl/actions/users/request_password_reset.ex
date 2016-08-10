defmodule Cogctl.Actions.Users.RequestPasswordReset do
  use Cogctl.Action, "users request password reset"

  def option_spec do
    [{:email_address, :undefined, :undefined, :string, 'Email address of user to reset password (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    email_address = Keyword.get(options, :email_address)

    case CogApi.HTTP.Users.request_password_reset(endpoint, email_address) do
      :ok -> :ok
      {:error, error} -> display_error(error)
    end
  end
end

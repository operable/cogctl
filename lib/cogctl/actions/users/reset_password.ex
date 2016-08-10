defmodule Cogctl.Actions.Users.ResetPassword do
  use Cogctl.Action, "users reset password"

  def option_spec do
    [{:token, :undefined, :undefined, :string, 'Password reset token (required)'},
     {:password, :undefined, :undefined, :string, 'New password (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    token = Keyword.get(options, :token)
    password = Keyword.get(options, :password)

    case CogApi.HTTP.Users.reset_password(endpoint, token, password) do
      {:ok, _user} -> :ok
      {:error, error} -> display_error(error)
    end
  end
end


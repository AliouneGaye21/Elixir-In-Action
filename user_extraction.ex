defmodule UserExtraction do
  def extract_user(user) do
    with {:ok, login} <- extract_login(user),
         {:ok, email} <- extract_email(user),
         {:ok, password} <- extract_password(user) do
      {:ok, %{login: login, email: email, password: password}}
    else
      {:error, "Login not found or invalid"} -> {:error, "login missing"}
      {:error, "Email not found or invalid"} -> {:error, "email missing"}
      {:error, "Password not found or invalid"} -> {:error, "password missing"}
    end
  end

  defp extract_login(%{"login" => login}) when is_binary(login), do: {:ok, login}
  defp extract_login(_), do: {:error, "Login not found or invalid"}

  defp extract_email(%{"email" => email}) when is_binary(email), do: {:ok, email}
  defp extract_email(_), do: {:error, "Email not found or invalid"}

  defp extract_password(%{"password" => password}) when is_binary(password), do: {:ok, password}
  defp extract_password(_), do: {:error, "Password not found or invalid"}
end

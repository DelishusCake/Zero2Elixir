defmodule Microservice.Token do
  def sign(salt, data, opts \\ []) do
    # Get the secret key to sign the token with
    secret = get_secret_key_base()
    # Sign the token
    Plug.Crypto.sign(secret, salt, data, opts)
  end

  def verify(salt, token, opts \\ []) do
    # Get the secret key to verify the token with
    secret = get_secret_key_base()
    # Verify the token
    Plug.Crypto.verify(secret, salt, token, opts)
  end

  defp get_secret_key_base(), do: Application.get_env(:microservice, :secret_key_base, 8080) || raise "Secret key base not defined"
end
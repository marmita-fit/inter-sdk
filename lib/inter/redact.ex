defmodule Inter.Redact do
  @moduledoc """
  Helpers to strip credentials and secrets before anything gets logged.

  Only credentials are masked here (`client_secret`, `cert_file`, `key_file`,
  `access_token`, the `Authorization` header). Request/response bodies (which
  may contain CPF, monetary values, etc.) are logged as-is by design — see
  the "Debug e observabilidade" section in the README for how to turn that
  off via `config :inter, :log_bodies, false`.
  """

  @secret_keys ~w(client_secret cert_file key_file access_token)

  @doc "Redacts known secret fields from a client/request-ish map or struct."
  def client(%_{} = struct), do: struct |> Map.from_struct() |> client()

  def client(map) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} ->
      if to_string(key) in @secret_keys do
        {key, "[REDACTED]"}
      else
        {key, value}
      end
    end)
  end

  def client(other), do: other

  @doc "Redacts the Authorization header, keeping only a short suffix for correlation."
  def headers(headers) when is_list(headers) do
    Enum.map(headers, fn
      {"Authorization", "Bearer " <> token} ->
        {"Authorization", "Bearer ***" <> String.slice(token, -6, 6)}

      {"Authorization", _value} ->
        {"Authorization", "[REDACTED]"}

      header ->
        header
    end)
  end

  @doc "Redacts the OAuth token request body (client_id/client_secret form-encoded pairs)."
  def form_data(data) when is_list(data) do
    Enum.map(data, fn
      {"client_secret", _value} -> {"client_secret", "[REDACTED]"}
      pair -> pair
    end)
  end
end

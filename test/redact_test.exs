defmodule Inter.RedactTest do
  use ExUnit.Case, async: true

  describe "client/1" do
    test "masks secret fields on a Client struct" do
      client = %Inter.Client{
        client_id: "my_client_id",
        client_secret: "super-secret",
        cert_file: "-----BEGIN CERTIFICATE-----",
        key_file: "-----BEGIN PRIVATE KEY-----",
        token: %Inter.Token{access_token: "should-not-be-masked-here"}
      }

      redacted = Inter.Redact.client(client)

      assert redacted.client_id == "my_client_id"
      assert redacted.client_secret == "[REDACTED]"
      assert redacted.cert_file == "[REDACTED]"
      assert redacted.key_file == "[REDACTED]"
    end
  end

  describe "headers/1" do
    test "masks the Authorization bearer token, keeping a short suffix" do
      headers = [
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer abc123456789"}
      ]

      assert Inter.Redact.headers(headers) == [
               {"Content-Type", "application/json"},
               {"Authorization", "Bearer ***456789"}
             ]
    end
  end

  describe "form_data/1" do
    test "masks client_secret in the oauth token form body" do
      data = [
        {"client_id", "my_id"},
        {"client_secret", "super-secret"},
        {"scope", "pix.write"}
      ]

      assert Inter.Redact.form_data(data) == [
               {"client_id", "my_id"},
               {"client_secret", "[REDACTED]"},
               {"scope", "pix.write"}
             ]
    end
  end
end

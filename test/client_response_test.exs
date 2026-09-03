defmodule Inter.ClientResponseTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Regression coverage for the bug behind the "gerar PIX falhou e não sabíamos
  o porquê" incident: any unmapped HTTP status or network error used to fall
  through to a hardcoded `"Failed to obtain OAuth token"` message, no matter
  which operation actually failed.
  """

  describe "success responses" do
    test "decodes a 200 into the given type" do
      response = {:ok, %HTTPoison.Response{status_code: 200, body: ~s({"access_token":"abc"})}}

      {value, metadata} = Inter.Client.handle_response(response, :fetch_token, Inter.Token)

      assert %Inter.Token{access_token: "abc"} = value
      assert metadata == %{status_code: 200, result: :ok}
    end
  end

  describe "unmapped HTTP status codes (e.g. 500 during an outage)" do
    test "identifies the failing operation instead of a generic token message" do
      response = {:ok, %HTTPoison.Response{status_code: 500, body: "internal error"}}

      {{:error, message, _response}, metadata} =
        Inter.Client.handle_response(response, :pix_charge, Inter.Pix.Charge.Response)

      assert message =~ "pix_charge"
      assert message =~ "500"
      refute message =~ "Failed to obtain OAuth token"
      assert metadata == %{status_code: 500, result: :error, reason: "internal error"}
    end
  end

  describe "network errors (timeout, connection refused)" do
    test "identifies the failing operation and the real reason" do
      response = {:error, %HTTPoison.Error{reason: :timeout}}

      {{:error, message, _error}, metadata} =
        Inter.Client.handle_response(response, :pix_charge, Inter.Pix.Charge.Response)

      assert message =~ "pix_charge"
      assert message =~ "timeout"
      refute message =~ "Failed to obtain OAuth token"
      assert metadata == %{result: :error, reason: :timeout}
    end

    test "also identifies non-pix operations correctly" do
      response = {:error, %HTTPoison.Error{reason: :econnrefused}}

      {{:error, message, _error}, _metadata} =
        Inter.Client.handle_response(response, :cobranca_charge, Inter.Cobranca.Charge.Response)

      assert message =~ "cobranca_charge"
      assert message =~ "econnrefused"
    end
  end

  describe "known error status codes" do
    test "403 keeps the raw body for the caller" do
      response = {:ok, %HTTPoison.Response{status_code: 403, body: "forbidden"}}

      {{:error, "forbidden", _response}, metadata} =
        Inter.Client.handle_response(response, :pix_charge, Inter.Pix.Charge.Response)

      assert metadata == %{status_code: 403, result: :error, reason: "forbidden"}
    end

    test "429 returns a rate-limit specific message" do
      response = {:ok, %HTTPoison.Response{status_code: 429, body: ""}}

      {{:error, message, _response}, metadata} =
        Inter.Client.handle_response(response, :pix_charge, Inter.Pix.Charge.Response)

      assert message =~ "rate-limited"
      assert metadata.status_code == 429
    end
  end
end

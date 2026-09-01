defmodule Inter do
  alias QRCode.Generator

  require Inter.Protocols

  @moduledoc """
  Documentation for `Inter`.
  """

  def pix_charge(%Inter.Pix.Charge.Request{} = request) do
    Inter.TokenManager.get_client()
    |> Inter.Client.pix_charge(request)
  end

  def get_pix(txid) do
    case txid do
      _ -> Inter.TokenManager.get_client() |> Inter.Client.get_pix(txid)
    end
  end

  def cobranca_charge(%Inter.Cobranca.Charge.Request{} = request) do
    Inter.TokenManager.get_client()
    |> Inter.Client.cobranca_charge(request)
  end

  def get_cobranca(cod, conta_corrente) do
    case cod do
      _ -> Inter.TokenManager.get_client() |> Inter.Client.get_cobranca(cod, conta_corrente)
    end
  end

  @doc """
  Fetches the boleto PDF (base64-encoded) for a `codigoSolicitacao`.

  Use `Inter.Cobranca.Charge.Response.PdfResponse.decode/1` to get the raw
  PDF bytes out of the response.
  """
  def get_cobranca_pdf(cod, conta_corrente) do
    Inter.TokenManager.get_client() |> Inter.Client.get_cobranca_pdf(cod, conta_corrente)
  end

  def create_webhook(%Inter.Webhook.Request{} = request, type \\ :boleto) do
    Inter.TokenManager.get_client()
    |> Inter.Client.create_webhook(request, type)
  end

  def get_webhook(%Inter.Webhook.Request{} = request, type \\ :boleto) do
    Inter.TokenManager.get_client()
    |> Inter.Client.get_webhook(request, type)
  end

  def pix_qr_code(%Inter.Pix.Charge.Response{} = response) do
    %Inter.Pix.Charge.Response{
      response
      | qrCode: Generator.generate(response.pixCopiaECola, :svg)
    }
  end
end

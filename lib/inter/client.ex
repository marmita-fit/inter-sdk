defmodule Inter.Client do
  @moduledoc """
  Documentation for `Inter.Client`.
  """

  defstruct [
    :base_url,
    :client_id,
    :client_secret,
    :scope,
    :grant_type,
    :cert_file,
    :key_file,
    :token,
    :request,
    :request_options,
    :response
  ]

  @defaults %{
    grant_type: "client_credentials",
    base_url: "https://cdpj.partners.bancointer.com.br/"
  }

  @doc """
  Build new client.

  ## Examples

      iex> Inter.Client.new("some_client_id", "some_client_secret", "scope", "grant_type", "cert_file", "key_file")
      %Inter.Client{
         base_url: "https://cdpj.partners.bancointer.com.br/",
         client_id: "some_client_id",
         client_secret: "some_client_secret",
         scope: "scope",
         grant_type: "grant_type",
         cert_file: "cert_file",
         key_file: "key_file"
       }
  """
  def new(
        client_id,
        client_secret,
        scope,
        grant_type,
        cert_file,
        key_file,
        url \\ "https://cdpj.partners.bancointer.com.br/"
      ) do
    {type, encoded, _atom} = key_file |> :public_key.pem_decode() |> hd()

    %__MODULE__{
      base_url: url,
      client_id: client_id,
      client_secret: client_secret,
      scope: scope,
      grant_type: grant_type,
      cert_file: cert_file,
      key_file: key_file,
      request_options: [
        recv_timeout: 30_000,
        ssl: [
          versions: [:"tlsv1.2"],
          cert: cert_file |> :public_key.pem_decode() |> hd() |> elem(1),
          key: {type, encoded}
        ]
      ]
    }
  end

  def new(opts) when is_list(opts) do
    opts = Enum.into(opts, %{})

    {type, encoded, _atom} = opts.key_file |> :public_key.pem_decode() |> hd()
    cert = opts.cert_file |> :public_key.pem_decode() |> hd() |> elem(1)

    attrs =
      @defaults
      |> Map.merge(opts)
      |> Map.merge(%{
        request_options: [
          recv_timeout: 30_000,
          ssl: [
            versions: [:"tlsv1.2"],
            cert: cert,
            key: {type, encoded}
          ]
        ]
      })

    struct(__MODULE__, attrs)
  end

  def fetch_token(%__MODULE__{} = client) do
    data = [
      {"client_id", client.client_id},
      {"client_secret", client.client_secret},
      {"scope", client.scope},
      {"grant_type", client.grant_type}
    ]

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    url = client.base_url <> "oauth/v2/token"

    request(:fetch_token, "POST", url, %{body: Inter.Redact.form_data(data)}, fn ->
      HTTPoison.post(url, {:form, data}, headers, client.request_options)
      |> handle_response(:fetch_token, Inter.Token)
    end)
  end

  def pix_charge(%__MODULE__{} = client, %Inter.Pix.Charge.Request{} = request) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token}
    ]

    body = Poison.encode!(request |> Nestru.encode!())
    url = client.base_url <> "pix/v2/cob"

    request(:pix_charge, "POST", url, %{body: body}, fn ->
      HTTPoison.post(url, body, headers, client.request_options)
      |> handle_response(:pix_charge, Inter.Pix.Charge.Response)
    end)
  end

  def get_pix(%__MODULE__{} = client, txid) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token}
    ]

    url = client.base_url <> "pix/v2/cob/#{txid}"

    response =
      request(:get_pix, "GET", url, %{txid: txid}, fn ->
        HTTPoison.get(url, headers, client.request_options)
        |> handle_response(:get_pix, Inter.Pix.Charge.Response)
      end)

    %__MODULE__{client | request: %{}, response: response}
  end

  def get_cobranca(%__MODULE__{} = client, cod, conta_corrente) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token},
      {"X-Conta-Corrente", conta_corrente}
    ]

    url = client.base_url <> "cobranca/v3/cobrancas/#{cod}"

    response =
      request(:get_cobranca, "GET", url, %{cod: cod}, fn ->
        HTTPoison.get(url, headers, client.request_options)
        |> handle_response(:get_cobranca, Inter.Cobranca.Charge.Response)
      end)

    %__MODULE__{client | request: %{}, response: response}
  end

  def cobranca_charge(%__MODULE__{} = client, %Inter.Cobranca.Charge.Request{} = request) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token},
      {"X-Conta-Corrente", request.contaCorrente}
    ]

    body = Poison.encode!(request |> Nestru.encode!())
    url = client.base_url <> "cobranca/v3/cobrancas"

    response =
      request(:cobranca_charge, "POST", url, %{body: body}, fn ->
        HTTPoison.post(url, body, headers, client.request_options)
        |> handle_response(:cobranca_charge, Inter.Cobranca.Charge.Response.SimpleResponse)
      end)

    %__MODULE__{client | request: request, response: response}
  end

  def create_webhook(%__MODULE__{} = client, %Inter.Webhook.Request{} = request, type \\ :boleto) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token},
      {"X-Conta-Corrente", request.contaCorrente}
    ]

    path =
      case type do
        :boleto -> "cobranca/v3/cobrancas/webhook"
        :pix -> "pix/v2/webhook/#{request.chavePix}"
      end

    body = Poison.encode!(request |> Nestru.encode!())
    url = client.base_url <> path

    response =
      request(:create_webhook, "PUT", url, %{body: body}, fn ->
        HTTPoison.put(url, body, headers, client.request_options)
        |> handle_response(:create_webhook, Inter.Webhook.Response)
      end)

    %__MODULE__{client | request: request, response: response}
  end

  def get_webhook(%__MODULE__{} = client, %Inter.Webhook.Request{} = request, type \\ :boleto) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token},
      {"X-Conta-Corrente", request.contaCorrente}
    ]

    path =
      case type do
        :boleto -> "cobranca/v3/cobrancas/webhook"
        :pix -> "pix/v2/webhook/#{request.chavePix}"
      end

    url = client.base_url <> path

    response =
      request(:get_webhook, "GET", url, %{}, fn ->
        HTTPoison.get(url, headers, client.request_options)
        |> handle_response(:get_webhook, Inter.Webhook.Response)
      end)

    %__MODULE__{client | request: request, response: response}
  end

  defp request(operation, method, url, extra_metadata, fun) do
    Inter.Telemetry.span(operation, Map.merge(%{method: method, url: url}, extra_metadata), fun)
  end

  @doc false
  def handle_response({:ok, %HTTPoison.Response{status_code: status, body: body}}, _operation, type)
      when status in [200, 201] do
    value = body |> Jason.decode!() |> Nestru.decode!(type)
    {value, %{status_code: status, result: :ok}}
  end

  def handle_response(
        {:ok, %HTTPoison.Response{status_code: 403, body: body} = response},
        _operation,
        _type
      ) do
    {{:error, body, response}, %{status_code: 403, result: :error, reason: body}}
  end

  def handle_response(
        {:ok, %HTTPoison.Response{status_code: 400, body: body} = response},
        _operation,
        _type
      ) do
    decoded = body |> Jason.decode!()
    {{:error, decoded, response}, %{status_code: 400, result: :error, reason: decoded}}
  end

  def handle_response(
        {:ok, %HTTPoison.Response{status_code: 429} = response},
        _operation,
        _type
      ) do
    reason = "You've been rate-limited, try again later (429 error)"
    {{:error, reason, response}, %{status_code: 429, result: :error, reason: reason}}
  end

  def handle_response(
        {:ok, %HTTPoison.Response{status_code: status, body: body} = response},
        operation,
        _type
      ) do
    reason = "#{operation} returned an unexpected status code (#{status}): #{body}"
    {{:error, reason, response}, %{status_code: status, result: :error, reason: body}}
  end

  def handle_response({:error, %HTTPoison.Error{reason: reason} = error}, operation, _type) do
    message = "#{operation} failed due to a network/connection error: #{inspect(reason)}"
    {{:error, message, error}, %{result: :error, reason: reason}}
  end
end

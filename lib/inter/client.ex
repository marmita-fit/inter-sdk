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

    HTTPoison.post(
      client.base_url <> "oauth/v2/token",
      {:form, data},
      headers,
      client.request_options
    )
    |> handle_response(Inter.Token)
  end

  def pix_charge(%__MODULE__{} = client, %Inter.Pix.Charge.Request{} = request) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token}
    ]

    response =
      HTTPoison.post(
        client.base_url <> "pix/v2/cob",
        Poison.encode!(request |> Nestru.encode!()),
        headers,
        client.request_options
      )

    handle_response(response, Inter.Pix.Charge.Response)
  end

  def get_pix(%__MODULE__{} = client, txid) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token}
    ]

    response =
      HTTPoison.get(
        client.base_url <> "pix/v2/cob/#{txid}",
        headers,
        client.request_options
      )

    %__MODULE__{
      client
      | request: %{},
        response: handle_response(response, Inter.Pix.Charge.Response)
    }
  end

  def get_cobranca(%__MODULE__{} = client, cod, conta_corrente) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token},
      {"X-Conta-Corrente", conta_corrente}
    ]

    response =
      HTTPoison.get(
        client.base_url <> "cobranca/v3/cobrancas/#{cod}",
        headers,
        client.request_options
      )

    %__MODULE__{
      client
      | request: %{},
        response: handle_response(response, Inter.Cobranca.Charge.Response)
    }
  end

  def get_cobranca_pdf(%__MODULE__{} = client, cod, conta_corrente) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token},
      {"X-Conta-Corrente", conta_corrente}
    ]

    response =
      HTTPoison.get(
        client.base_url <> "cobranca/v3/cobrancas/#{cod}/pdf",
        headers,
        client.request_options
      )

    %__MODULE__{
      client
      | request: %{},
        response: handle_response(response, Inter.Cobranca.Charge.Response.PdfResponse)
    }
  end

  def cobranca_charge(%__MODULE__{} = client, %Inter.Cobranca.Charge.Request{} = request) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> client.token.access_token},
      {"X-Conta-Corrente", request.contaCorrente}
    ]

    response =
      HTTPoison.post(
        client.base_url <> "cobranca/v3/cobrancas",
        Poison.encode!(request |> Nestru.encode!()),
        headers,
        client.request_options
      )

    %__MODULE__{
      client
      | request: request,
        response: handle_response(response, Inter.Cobranca.Charge.Response.SimpleResponse)
    }
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

    response =
      HTTPoison.put(
        client.base_url <> path,
        Poison.encode!(request |> Nestru.encode!()),
        headers,
        client.request_options
      )

    %__MODULE__{
      client
      | request: request,
        response: handle_response(response, Inter.Webhook.Response)
    }
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

    response =
      HTTPoison.get(
        client.base_url <> path,
        headers,
        client.request_options
      )

    %__MODULE__{
      client
      | request: request,
        response: handle_response(response, Inter.Webhook.Response)
    }
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, type),
    do: body |> Jason.decode!() |> Nestru.decode!(type)

  defp handle_response({:ok, %HTTPoison.Response{status_code: 201, body: body}}, type),
    do: body |> Jason.decode!() |> Nestru.decode!(type)

  defp handle_response(
         {:ok, %HTTPoison.Response{status_code: 403, body: body} = response},
         _type
       ),
       do: {:error, body, response}

  defp handle_response(
         {:ok, %HTTPoison.Response{status_code: 400, body: body}} = response,
         _type
       ),
       do: {:error, body |> Jason.decode!(), response}

  defp handle_response({:ok, %HTTPoison.Response{status_code: 429}} = response, _type),
    do: {:error, "You've been rate-limited, try again later (429 error)", response}

  defp handle_response(response, _type), do: {:error, "Failed to obtain OAuth token", response}
end

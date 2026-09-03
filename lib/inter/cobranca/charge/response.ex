defmodule Inter.Cobranca.Charge.Response do
  @derive [Nestru.Encoder, Nestru.Decoder]
  defstruct cobranca: nil,
            boleto: nil,
            pix: nil

  defmodule SimpleResponse do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct codigoSolicitacao: nil
  end

  defmodule PdfResponse do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct pdf: nil

    @doc """
    Decodes the base64-encoded `pdf` field into raw PDF bytes.

    ## Examples

        iex> Inter.Cobranca.Charge.Response.PdfResponse.decode(%Inter.Cobranca.Charge.Response.PdfResponse{pdf: "aGVsbG8="})
        {:ok, "hello"}
    """
    def decode(%__MODULE__{pdf: pdf}), do: Base.decode64(pdf)
  end

  defmodule Cobranca do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct codigoSolicitacao: nil,
              seuNumero: nil,
              dataEmissao: nil,
              dataVencimento: nil,
              valorNominal: nil,
              tipoCobranca: nil,
              situacao: nil,
              dataSituacao: nil,
              valorTotalRecebido: nil,
              origemRecebimento: nil,
              arquivada: nil,
              descontos: [],
              multa: nil,
              mora: nil,
              pagador: nil
  end

  defmodule Desconto do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct codigo: nil,
              quantidadeDias: nil,
              taxa: nil
  end

  defmodule Multa do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct codigo: nil,
              valor: nil
  end

  defmodule Mora do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct codigo: nil,
              taxa: nil
  end

  defmodule Pagador do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct email: nil,
              ddd: nil,
              telefone: nil,
              numero: nil,
              complemento: nil,
              cpfCnpj: nil,
              tipoPessoa: nil,
              nome: nil,
              endereco: nil,
              bairro: nil,
              cidade: nil,
              uf: nil,
              cep: nil
  end

  defmodule Boleto do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct nossoNumero: nil,
              codigoBarras: nil,
              linhaDigitavel: nil
  end

  defmodule Pix do
    @derive [Nestru.Encoder, Nestru.Decoder]
    defstruct txid: nil,
              pixCopiaECola: nil
  end
end

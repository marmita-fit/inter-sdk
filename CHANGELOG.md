# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2026-09-01

### Added

- Instrumentação via `:telemetry` em toda chamada HTTP do `Inter.Client` (`fetch_token`, `pix_charge`, `get_pix`, `cobranca_charge`, `get_cobranca`, `create_webhook`, `get_webhook`), com eventos `[:inter, :request, :start | :stop | :exception]`.
- Handler de log padrão (`Inter.Telemetry.Logger`), anexado automaticamente, logando cada request/resposta/erro via `Logger` com `request_id` de correlação. Veja a seção "Debug e observabilidade" do README.
- Configs `config :inter, :log_bodies` e `:attach_default_logger` para controlar a verbosidade dos logs.
- `Inter.Redact` para mascarar credenciais (`client_secret`, `cert_file`, `key_file`, `access_token`, header `Authorization`) antes de qualquer log.

### Fixed

- `Inter.Client` retornava a mensagem genérica e enganosa `"Failed to obtain OAuth token"` para **qualquer** erro não mapeado (timeout, erro de conexão, status 5xx), mesmo em chamadas que não tinham nada a ver com autenticação (ex. `pix_charge`). Agora a mensagem de erro sempre identifica a operação e a causa real da falha.

## [0.5.0] - 2025-06-09

### Added

- Functions related to the "Boleto cobrança - https://developers.inter.co/references/cobranca-bolepix#tag/Cobranca/operation/emitirCobrancaAsync" (#6) @brunoocasali
- Added basic test coverage for the new feature (#6) @brunoocasali

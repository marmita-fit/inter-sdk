# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2026-09-25

### Breaking

- The webhook creation function was mistakenly named `Inter.cobranca_charge/2`, clashing with the boleto charge function. It was renamed to `Inter.create_webhook/2`; callers of the old name must update @brunoocasali

### Added

- `Inter.get_cobranca_pdf/2` and `Inter.Client.get_cobranca_pdf/3` to fetch the boleto PDF of a cobrança (`GET cobranca/v3/cobrancas/{codigoSolicitacao}/pdf`) @brunoocasali
- `Inter.Cobranca.Charge.Response.PdfResponse` struct, with `decode/1` to turn the base64 `pdf` field into raw PDF bytes @brunoocasali

## [0.6.0] - 2025-06-21

### Breaking

- The public functions in `Inter` no longer take an `%Inter.Client{}`. They get the authenticated client from `Inter.TokenManager`, which must be started in your supervision tree (#7) @brunoocasali
- `Inter.Client.token/1` was renamed to `Inter.Client.fetch_token/1` and now returns the `%Inter.Token{}` instead of the client (#7) @brunoocasali
- `Inter.Client.pix_charge/2` now returns the `%Inter.Pix.Charge.Response{}` instead of the client (#7) @brunoocasali
- `Inter.pix_qr_code/1` now takes an `%Inter.Pix.Charge.Response{}` and returns it with `qrCode` filled in (#7) @brunoocasali

### Added

- `Inter.TokenManager` GenServer that holds the client, fetches the OAuth token and refreshes it before it expires (#7) @brunoocasali
- `Inter.TokenFetcher` behaviour, so the token fetcher can be swapped (e.g. in tests) (#7) @brunoocasali
- `Inter.Client.new/1` accepting a keyword list, with defaults for `grant_type` and `base_url` (#7) @brunoocasali
- Webhook support for boleto and PIX: `Inter.get_webhook/2`, `Inter.Client.create_webhook/3`, `Inter.Client.get_webhook/3`, and the `Inter.Webhook.Request` / `Inter.Webhook.Response` structs (#7) @brunoocasali
- `Nestru.Encoder` implementation for `Decimal`, so decimal values are encoded as strings (#7) @brunoocasali
- `decimal` dependency (#7) @brunoocasali

### Changed

- Repository moved to https://github.com/marmita-fit/inter-sdk (#7) @brunoocasali
- `mox` is now a test-only dependency (#7) @brunoocasali

## [0.5.0] - 2025-06-09

### Added

- Functions related to the "Boleto cobrança - https://developers.inter.co/references/cobranca-bolepix#tag/Cobranca/operation/emitirCobrancaAsync" (#6) @brunoocasali
- Added basic test coverage for the new feature (#6) @brunoocasali

defmodule Inter.Telemetry do
  @moduledoc """
  Wraps every outgoing HTTP call made by `Inter.Client` in a `:telemetry`
  span, so failures (network errors, unexpected status codes, timeouts) are
  always observable instead of silently turning into a generic error.

  Events emitted, all under the `[:inter, :request, *]` prefix:

    * `[:inter, :request, :start]` — metadata: `:operation`, `:method`, `:url`, `:request_id`
    * `[:inter, :request, :stop]` — metadata above + `:status_code`, `:result` (`:ok` | `:error`), `:reason`
    * `[:inter, :request, :exception]` — metadata above + `:kind`, `:reason`

  A default handler (`Inter.Telemetry.Logger`) is attached automatically by
  `Inter.Application` and logs each event via `Logger`. Attach your own
  handler on the same events to build metrics/alerts (e.g. count failed PIX
  charges) without touching this SDK again.
  """

  @doc """
  Runs `fun` inside a telemetry span tagged with `operation`, generating a
  short `request_id` used to correlate the start/stop/exception log lines of
  a single call.

  `fun` must return `{result, extra_metadata}`, where `result` is whatever
  the wrapped function would normally return, and `extra_metadata` is a map
  merged into the `:stop` event (e.g. `%{status_code: 200, result: :ok}`).
  """
  def span(operation, metadata, fun) when is_atom(operation) and is_function(fun, 0) do
    request_id = generate_request_id()
    metadata = Map.merge(metadata, %{operation: operation, request_id: request_id})

    :telemetry.span([:inter, :request], metadata, fn ->
      {result, extra_metadata} = fun.()
      {result, Map.merge(metadata, extra_metadata)}
    end)
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)
  end
end

defmodule Inter.Telemetry.Logger do
  @moduledoc """
  Default `:telemetry` handler that logs every `Inter.Client` request. See
  `Inter.Telemetry` for the events it listens to, and the README's "Debug e
  observabilidade" section for how to disable or replace it.
  """
  require Logger

  @events [
    [:inter, :request, :start],
    [:inter, :request, :stop],
    [:inter, :request, :exception]
  ]

  def attach do
    :telemetry.attach_many("inter-default-logger", @events, &__MODULE__.handle_event/4, nil)
  end

  def detach do
    :telemetry.detach("inter-default-logger")
  end

  def handle_event([:inter, :request, :start], _measurements, metadata, _config) do
    log(
      :debug,
      metadata,
      "iniciando #{metadata.operation} #{metadata.method} #{metadata.url}#{body_suffix(metadata)}"
    )
  end

  def handle_event([:inter, :request, :stop], measurements, metadata, _config) do
    duration_ms = native_to_ms(measurements.duration)

    case metadata do
      %{status_code: status} when status in 200..299 ->
        log(
          :info,
          metadata,
          "#{metadata.operation} concluido com sucesso (status=#{status}, #{duration_ms}ms)"
        )

      %{status_code: status} when status in 400..499 ->
        log(
          :warning,
          metadata,
          "#{metadata.operation} retornou erro do cliente (status=#{status}, #{duration_ms}ms): #{inspect(Map.get(metadata, :reason))}"
        )

      %{status_code: status} ->
        log(
          :error,
          metadata,
          "#{metadata.operation} retornou status inesperado (status=#{status}, #{duration_ms}ms): #{inspect(Map.get(metadata, :reason))}"
        )

      _ ->
        log(
          :error,
          metadata,
          "#{metadata.operation} falhou (#{duration_ms}ms): #{inspect(Map.get(metadata, :reason))}"
        )
    end
  end

  def handle_event([:inter, :request, :exception], measurements, metadata, _config) do
    duration_ms = native_to_ms(measurements.duration)

    log(
      :error,
      metadata,
      "#{metadata.operation} levantou #{metadata.kind} (#{duration_ms}ms): #{inspect(metadata.reason)}"
    )
  end

  defp log(level, metadata, message) do
    Logger.log(level, "[Inter][#{metadata.request_id}] " <> message)
  end

  defp body_suffix(%{body: body}) do
    if Application.get_env(:inter, :log_bodies, true) do
      " body=#{inspect(body)}"
    else
      ""
    end
  end

  defp body_suffix(_metadata), do: ""

  defp native_to_ms(duration), do: System.convert_time_unit(duration, :native, :millisecond)
end

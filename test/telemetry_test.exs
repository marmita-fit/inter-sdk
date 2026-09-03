defmodule Inter.TelemetryTest do
  use ExUnit.Case, async: false

  @events [
    [:inter, :request, :start],
    [:inter, :request, :stop],
    [:inter, :request, :exception]
  ]

  setup do
    test_pid = self()
    handler_id = "test-handler-#{System.unique_integer()}"

    :telemetry.attach_many(
      handler_id,
      @events,
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  test "emits start/stop with :ok metadata on success" do
    Inter.Telemetry.span(:pix_charge, %{method: "POST", url: "https://example.test/pix"}, fn ->
      {:ok, %{status_code: 200, result: :ok}}
    end)

    assert_received {:telemetry_event, [:inter, :request, :start], _measurements, start_meta}
    assert start_meta.operation == :pix_charge
    assert is_binary(start_meta.request_id)

    assert_received {:telemetry_event, [:inter, :request, :stop], measurements, stop_meta}
    assert stop_meta.status_code == 200
    assert stop_meta.result == :ok
    assert stop_meta.request_id == start_meta.request_id
    assert measurements.duration >= 0
  end

  test "emits start/stop with :error metadata and reason on a failed call" do
    Inter.Telemetry.span(:pix_charge, %{method: "POST", url: "https://example.test/pix"}, fn ->
      {{:error, "boom"}, %{status_code: 500, result: :error, reason: "boom"}}
    end)

    assert_received {:telemetry_event, [:inter, :request, :stop], _measurements, stop_meta}
    assert stop_meta.status_code == 500
    assert stop_meta.result == :error
    assert stop_meta.reason == "boom"
  end

  test "emits exception when the wrapped function raises" do
    assert_raise RuntimeError, fn ->
      Inter.Telemetry.span(:pix_charge, %{method: "POST", url: "https://example.test/pix"}, fn ->
        raise "network exploded"
      end)
    end

    assert_received {:telemetry_event, [:inter, :request, :exception], _measurements, meta}
    assert meta.operation == :pix_charge
    assert meta.kind == :error
    assert %RuntimeError{message: "network exploded"} = meta.reason
  end
end

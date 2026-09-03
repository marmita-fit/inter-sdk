defmodule Inter.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    if Application.get_env(:inter, :attach_default_logger, true) do
      Inter.Telemetry.Logger.attach()
    end

    Supervisor.start_link([], strategy: :one_for_one, name: Inter.Supervisor)
  end
end

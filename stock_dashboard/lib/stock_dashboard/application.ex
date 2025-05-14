defmodule StockDashboard.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      StockDashboardWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: StockDashboard.PubSub},
      # Start the Endpoint (http/https)
      StockDashboardWeb.Endpoint,
      # Start the Stock Supervisor
      {StockDashboard.StockSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StockDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StockDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

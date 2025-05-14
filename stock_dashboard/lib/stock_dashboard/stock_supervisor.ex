defmodule StockDashboard.StockSupervisor do
  @moduledoc """
  Supervisor for stock-related processes
  """
  use Supervisor
  require Logger

  alias StockDashboard.Finnhub.Client

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("Starting Stock Supervisor")

    # Verify API key on startup
    api_status = Client.verify_api_key()
    Logger.info("Finnhub API key status: #{api_status}")

    # Load fallback data immediately if API key is invalid
    if api_status != :ok do
      Logger.warn("Using fallback data due to API key issues")
      Process.send_after(StockDashboard.StockManager, :check_cache, 1000)
    end

    children = [
      # Start the stock cache
      StockDashboard.StockCache,

      # Start the WebSocket client
      {StockDashboard.Finnhub.WebSocketClient, name: StockDashboard.Finnhub.WebSocketClient},

      # Start the stock manager
      StockDashboard.StockManager
    ]

    # Return the supervisor specification
    Supervisor.init(children, strategy: :one_for_one)
  end
end

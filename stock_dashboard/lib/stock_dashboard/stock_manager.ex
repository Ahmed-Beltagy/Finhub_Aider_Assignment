defmodule StockDashboard.StockManager do
  @moduledoc """
  Manages stock subscriptions and data
  """
  use GenServer
  require Logger

  alias StockDashboard.Finnhub.WebSocketClient
  alias StockDashboard.StockCache

  # List of stocks to track
  @stocks [
    # Technology
    "AAPL", "MSFT", "NVDA", "GOOGL",
    # Finance
    "JPM", "BAC", "V",
    # Consumer
    "AMZN", "WMT", "MCD"
  ]

  # Fallback data in case the API is not working
  @fallback_data %{
    "AAPL" => %{price: 175.50, timestamp: :os.system_time(:millisecond)},
    "MSFT" => %{price: 340.20, timestamp: :os.system_time(:millisecond)},
    "NVDA" => %{price: 450.75, timestamp: :os.system_time(:millisecond)},
    "GOOGL" => %{price: 135.60, timestamp: :os.system_time(:millisecond)},
    "JPM" => %{price: 145.30, timestamp: :os.system_time(:millisecond)},
    "BAC" => %{price: 32.40, timestamp: :os.system_time(:millisecond)},
    "V" => %{price: 240.80, timestamp: :os.system_time(:millisecond)},
    "AMZN" => %{price: 130.25, timestamp: :os.system_time(:millisecond)},
    "WMT" => %{price: 65.90, timestamp: :os.system_time(:millisecond)},
    "MCD" => %{price: 270.15, timestamp: :os.system_time(:millisecond)}
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule subscription after a short delay to ensure WebSocket client is ready
    Process.send_after(self(), :subscribe_to_stocks, 2000)

    # Schedule periodic cache check
    Process.send_after(self(), :check_cache, 10000)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:subscribe_to_stocks, state) do
    # Get the WebSocket client PID
    ws_client = Process.whereis(WebSocketClient)

    if ws_client do
      Logger.info("Subscribing to stocks: #{inspect(@stocks)}")

      # Subscribe to each stock
      Enum.each(@stocks, fn symbol ->
        WebSocketClient.subscribe(ws_client, symbol)
      end)
    else
      Logger.error("WebSocket client not found")
      # Retry after a delay
      Process.send_after(self(), :subscribe_to_stocks, 5000)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:reconnect_websocket, state) do
    Logger.info("Attempting to restart WebSocket client")

    # Try to terminate existing client if it's still around
    case Process.whereis(WebSocketClient) do
      nil -> :ok
      pid ->
        Logger.info("Terminating existing WebSocket client")
        Process.exit(pid, :kill)
    end

    # Start a new WebSocket client
    {:ok, _pid} = WebSocketClient.start_link(name: WebSocketClient)

    # Schedule resubscription
    Process.send_after(self(), :subscribe_to_stocks, 2000)

    {:noreply, state}
  end

  @impl true
  def handle_info(:check_cache, state) do
    # Check if we have any data in the cache
    stocks = StockCache.get_all_stocks()

    if Enum.empty?(stocks) do
      Logger.warn("Stock cache is empty, loading fallback data for all stocks")

      # Load fallback data into cache for all stocks
      Enum.each(@fallback_data, fn {symbol, data} ->
        StockCache.update_stock_price(symbol, data.price, data.timestamp, :fallback)
      end)
    else
      Logger.info("Stock cache has #{map_size(stocks)} symbols")

      # Check for missing stocks and load fallback data for them
      missing_stocks = @stocks -- Map.keys(stocks)

      if missing_stocks != [] do
        Logger.warn("Missing data for stocks: #{inspect(missing_stocks)}, loading fallback data")

        Enum.each(missing_stocks, fn symbol ->
          if Map.has_key?(@fallback_data, symbol) do
            data = @fallback_data[symbol]
            StockCache.update_stock_price(symbol, data.price, data.timestamp, :fallback)
          end
        end)
      end
    end

    # Schedule next check
    Process.send_after(self(), :check_cache, 30000)

    {:noreply, state}
  end
end

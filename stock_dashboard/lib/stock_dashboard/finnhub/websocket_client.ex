defmodule StockDashboard.Finnhub.WebSocketClient do
  @moduledoc """
  WebSocket client for Finnhub real-time data
  """
  use WebSockex
  require Logger

  alias StockDashboard.Finnhub.Client
  alias StockDashboard.StockCache
  alias StockDashboard.StockManager

  @reconnect_delay 5000

  def start_link(opts \\ []) do
    url = Client.websocket_url()
    Logger.info("Starting WebSocket connection to Finnhub: #{url}")
    WebSockex.start_link(url, __MODULE__, %{subscribed_symbols: []}, opts)
  end

  @doc """
  Subscribe to real-time price updates for a stock symbol
  """
  def subscribe(pid, symbol) do
    Logger.info("Subscribing to symbol: #{symbol}")
    message = Jason.encode!(%{type: "subscribe", symbol: symbol})

    # Store the subscription in the process state
    GenServer.cast(pid, {:add_subscription, symbol})

    # Send the subscription to Finnhub
    WebSockex.send_frame(pid, {:text, message})
  end

  @doc """
  Unsubscribe from real-time price updates for a stock symbol
  """
  def unsubscribe(pid, symbol) do
    Logger.info("Unsubscribing from symbol: #{symbol}")
    message = Jason.encode!(%{type: "unsubscribe", symbol: symbol})

    # Remove the subscription from the process state
    GenServer.cast(pid, {:remove_subscription, symbol})

    # Send the unsubscription to Finnhub
    WebSockex.send_frame(pid, {:text, message})
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Connected to Finnhub WebSocket")

    # If we have previously subscribed symbols, resubscribe to them
    if state.subscribed_symbols != [] do
      Logger.info("Resubscribing to #{length(state.subscribed_symbols)} symbols")

      Enum.each(state.subscribed_symbols, fn symbol ->
        message = Jason.encode!(%{type: "subscribe", symbol: symbol})
        WebSockex.send_frame(self(), {:text, message})
      end)
    end

    {:ok, state}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "trade", "data" => data}} ->
        # Process trade data
        Logger.debug("Received trade data for #{length(data)} trades")

        Enum.each(data, fn trade ->
          symbol = trade["s"]
          price = trade["p"]
          volume = trade["v"]
          timestamp = trade["t"]

          Logger.debug("Trade: #{symbol} @ #{price} (vol: #{volume})")

          # Store the latest price in ETS with source as real_time
          StockCache.update_stock_price(symbol, price, timestamp, :real_time)

          # Broadcast the update to all connected clients
          StockDashboardWeb.Endpoint.broadcast!("stocks:lobby", "price_update", %{
            symbol: symbol,
            price: price,
            volume: volume,
            timestamp: timestamp,
            source: :real_time
          })
      end)

      {:ok, %{"type" => "ping"}} ->
        Logger.debug("Received ping from Finnhub, sending pong")
        # Respond to ping with pong
        WebSockex.send_frame(self(), {:text, Jason.encode!(%{type: "pong"})})

      {:ok, other} ->
        Logger.info("Received other message: #{inspect(other)}")

      {:error, error} ->
        Logger.error("Error decoding message: #{inspect(error)}, Message: #{inspect(msg)}")
    end

    {:ok, state}
  end

  @impl true
  def handle_cast({:add_subscription, symbol}, state) do
    updated_symbols = [symbol | state.subscribed_symbols] |> Enum.uniq()
    {:ok, %{state | subscribed_symbols: updated_symbols}}
  end

  @impl true
  def handle_cast({:remove_subscription, symbol}, state) do
    updated_symbols = Enum.reject(state.subscribed_symbols, &(&1 == symbol))
    {:ok, %{state | subscribed_symbols: updated_symbols}}
  end

  @impl true
  def handle_info(info, state) do
    Logger.info("Received message: #{inspect(info)}")
    {:ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.warn("WebSocket Client Terminated: #{inspect(reason)}")

    # Schedule reconnection
    if reason != :normal do
      Logger.info("Scheduling reconnection in #{@reconnect_delay}ms")
      Process.send_after(StockManager, :reconnect_websocket, @reconnect_delay)
    end

    :ok
  end
end

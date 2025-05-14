defmodule StockDashboardWeb.StocksChannel do
  use StockDashboardWeb, :channel
  alias StockDashboard.StockCache

  @impl true
  def join("stocks:lobby", _payload, socket) do
    # Send initial stock data to the client
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Get all stocks from the cache and send them to the client
    stocks = StockCache.get_all_stocks()
    push(socket, "init_stocks", %{stocks: stocks})
    {:noreply, socket}
  end

  @impl true
  def handle_in("ping", %{"message" => msg}, socket) do
    {:reply, {:ok, %{message: "Pong! Got: #{msg}"}}, socket}
  end

  @impl true
  def handle_in("get_stock", %{"symbol" => symbol}, socket) do
    case StockCache.get_stock_price(symbol) do
      {:ok, data} ->
        {:reply, {:ok, %{symbol: symbol, data: data}}, socket}
      {:error, :not_found} ->
        {:reply, {:error, %{reason: "Stock not found"}}, socket}
    end
  end

  @impl true
  def handle_in("get_all_stocks", _payload, socket) do
    stocks = StockCache.get_all_stocks()
    {:reply, {:ok, %{stocks: stocks}}, socket}
  end
end

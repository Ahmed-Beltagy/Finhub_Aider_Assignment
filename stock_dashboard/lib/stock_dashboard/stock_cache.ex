defmodule StockDashboard.StockCache do
  @moduledoc """
  ETS-based cache for storing stock data
  """
  use GenServer
  require Logger

  @table_name :stock_cache

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Update stock price in the cache
  """
  def update_stock_price(symbol, price, timestamp, source \\ :real_time) do
    true = :ets.insert(@table_name, {symbol, %{price: price, timestamp: timestamp, source: source}})
    Logger.debug("Updated stock price: #{symbol} @ #{price} (source: #{source})")
    :ok
  end

  @doc """
  Get stock price from the cache
  """
  def get_stock_price(symbol) do
    case :ets.lookup(@table_name, symbol) do
      [{^symbol, data}] ->
        Logger.debug("Cache hit for #{symbol}: #{inspect(data)}")
        {:ok, data}
      [] ->
        Logger.debug("Cache miss for #{symbol}")
        {:error, :not_found}
    end
  end

  @doc """
  Get all stocks from the cache
  """
  def get_all_stocks do
    result = :ets.tab2list(@table_name)
    |> Enum.map(fn {symbol, data} -> {symbol, data} end)
    |> Enum.into(%{})

    Logger.debug("Retrieved #{map_size(result)} stocks from cache")
    result
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("Initializing stock cache")

    # Create ETS table for stock data
    :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])

    {:ok, %{}}
  end
end

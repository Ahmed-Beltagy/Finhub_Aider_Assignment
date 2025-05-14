defmodule StockDashboard.Finnhub.Client do
  @moduledoc """
  Client for interacting with the Finnhub API
  """
  require Logger

  @base_url "https://finnhub.io/api/v1"

  @doc """
  Get your API key from https://finnhub.io/
  """
  def api_key do
    # You should consider moving this to config
    "d0gj0rhr01qhao4tup4gd0gj0rhr01qhao4tup50"
  end

  @doc """
  Verify API key is valid
  """
  def verify_api_key do
    url = "#{@base_url}/stock/symbol?exchange=US&token=#{api_key()}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("Finnhub API key verified successfully")
        :ok
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        Logger.error("Finnhub API key is invalid or unauthorized")
        :error
      {:ok, %HTTPoison.Response{status_code: 429}} ->
        Logger.error("Finnhub API rate limit exceeded")
        :rate_limited
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Finnhub API error: #{status_code}, #{body}")
        :error
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error when verifying Finnhub API key: #{reason}")
        :error
    end
  end

  @doc """
  Get stock quote for a symbol
  """
  def get_quote(symbol) do
    url = "#{@base_url}/quote?symbol=#{symbol}&token=#{api_key()}"
    Logger.debug("Requesting quote for #{symbol}")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        data = Jason.decode!(body)
        Logger.debug("Received quote for #{symbol}: #{inspect(data)}")
        {:ok, data}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("API error for #{symbol}: #{status_code}, #{body}")
        {:error, "API error: #{status_code}, #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error for #{symbol}: #{reason}")
        {:error, "HTTP error: #{reason}"}
    end
  end

  @doc """
  Get company profile for a symbol
  """
  def get_company_profile(symbol) do
    url = "#{@base_url}/stock/profile2?symbol=#{symbol}&token=#{api_key()}"
    Logger.debug("Requesting company profile for #{symbol}")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        data = Jason.decode!(body)
        Logger.debug("Received company profile for #{symbol}: #{inspect(data)}")
        {:ok, data}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("API error for #{symbol} profile: #{status_code}, #{body}")
        {:error, "API error: #{status_code}, #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error for #{symbol} profile: #{reason}")
        {:error, "HTTP error: #{reason}"}
    end
  end

  @doc """
  Get WebSocket URL for real-time data
  """
  def websocket_url do
    "wss://ws.finnhub.io?token=#{api_key()}"
  end
end

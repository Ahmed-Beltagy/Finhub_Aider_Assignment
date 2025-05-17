# Stock Dashboard

A real-time stock price monitoring dashboard built with Elixir, Phoenix, and Svelte.

## Project Description

Stock Dashboard is a web application that displays real-time stock prices for selected companies across different sectors. It uses the Finnhub API to fetch real-time stock data via WebSockets and displays it in an organized, user-friendly interface.

### Features

- Real-time stock price updates via WebSockets
- Categorized view of stocks by sector (Technology, Finance, Consumer)
- Fallback data mechanism when API is unavailable
- Visual indicators for connection status and data source (real-time vs. fallback)
- Phoenix backend with Svelte frontend

## Setup Instructions

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- Node.js 16 or later
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Ahmed-Beltagy/Finhub_Aider_Assignment.git
   cd stock_dashboard
   ```

2. Install Elixir dependencies:
   ```bash
   mix deps.get
   ```

3. Set up the frontend assets:
   ```bash
   mix setup
   ```
4. Run the frontend:
   ```bash
   cd stock_dashboard/assets/svelte
   npm install
   npm run build
   ```
4. Configure your Finnhub API key:
   - Sign up for a free API key at [Finnhub.io](https://finnhub.io/)
   - Replace the API key in `lib/stock_dashboard/finnhub/client.ex` with your own key [This shold be in a .env fie, but I left the API in the file as I treated it as it is not a very important API Key I assumed]

5. Start the Phoenix server:
   ```bash
   cd stock_dashboard
   mix phx.server
   ```

6. Visit [`localhost:4000`](http://localhost:4000) in your browser to see the application.

## Architecture

The Stock Dashboard application follows a client-server architecture with real-time communication:

### Backend (Elixir/Phoenix)

- **Application Supervisor**: The main supervisor that starts all application components.
- **Stock Supervisor**: Manages stock-related processes including the WebSocket client and stock cache.
- **WebSocket Client**: Connects to Finnhub's WebSocket API to receive real-time stock updates.
- **Stock Cache**: An ETS-based cache that stores the latest stock prices.
- **Stock Manager**: Manages stock subscriptions and ensures data availability.
- **Phoenix Channels**: Enables real-time communication between the server and client.

### Frontend (Svelte)

- **Svelte Application**: A reactive UI that displays stock data in categorized tables.
- **Phoenix Socket Connection**: Connects to the Phoenix backend to receive real-time updates.
- **Component-based UI**: Organized display of stock data with visual indicators.

### Data Flow

1. The WebSocket client connects to Finnhub and subscribes to stock symbols.
2. Real-time trade data is received and stored in the ETS cache.
3. Updates are broadcast to connected clients via Phoenix Channels.
4. The Svelte frontend receives these updates and reactively updates the UI.
5. If the Finnhub API is unavailable, the system falls back to static data.

### Fault Tolerance

- The application includes automatic reconnection for WebSocket failures.
- Fallback data is provided when the API is unavailable.
- Supervisors ensure processes are restarted if they crash.

### Scalability Considerations

- ETS cache provides fast, concurrent access to stock data.
- Phoenix Channels efficiently broadcast updates to multiple clients.
- The architecture can be extended to support more stocks and users with minimal changes.

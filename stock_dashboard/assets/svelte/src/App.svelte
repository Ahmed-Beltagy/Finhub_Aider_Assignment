<script>                                                                                                                                                                                      
  import { onMount } from 'svelte';                                                                                                                                                           
  import { Socket } from 'phoenix';                                                                                                                                                           
                                                                                                                                                                                              
  let connected = false;                                                                                                                                                                      
  let message = "Connecting to Phoenix...";                                                                                                                                                   
  let stocks = {};                                                                                                                                                                            
                                                                                                                                                                                              
  // Group stocks by category                                                                                                                                                                 
  const stockCategories = {                                                                                                                                                                   
    Technology: ["AAPL", "MSFT", "NVDA", "GOOGL"],                                                                                                                                            
    Finance: ["JPM", "BAC", "V"],                                                                                                                                                             
    Consumer: ["AMZN", "WMT", "MCD"]                                                                                                                                                          
  };                                                                                                                                                                                          
                                                                                                                                                                                              
  onMount(() => {                                                                                                                                                                               
	// Connect to Phoenix socket                                                                                                                                                                
	const socket = new Socket("/socket");                                                                                                                                                       
	socket.connect();                                                                                                                                                                           
																																																
	// Join the stocks channel                                                                                                                                                                  
	const channel = socket.channel("stocks:lobby", {});                                                                                                                                         
																																																
	channel.join()                                                                                                                                                                              
		.receive("ok", resp => {                                                                                                                                                                  
		console.log("Joined successfully", resp);                                                                                                                                               
		connected = true;                                                                                                                                                                       
		message = "Connected to Phoenix backend!";                                                                                                                                              
																																																
		// Test the connection with a ping                                                                                                                                                      
		channel.push("ping", { message: "Hello from Svelte!" })                                                                                                                                 
			.receive("ok", (reply) => {                                                                                                                                                           
			console.log("Ping response:", reply);                                                                                                                                               
			});                                                                                                                                                                                   
																																																
		// Request initial stock data                                                                                                                                                           
		channel.push("get_all_stocks", {})                                                                                                                                                      
			.receive("ok", ({stocks: initialStocks}) => {                                                                                                                                         
			stocks = initialStocks;                                                                                                                                                             
			console.log("Initial stocks:", stocks);                                                                                                                                             
			});                                                                                                                                                                                   
		})                                                                                                                                                                                        
		.receive("error", resp => {                                                                                                                                                               
		console.log("Unable to join", resp);                                                                                                                                                    
		message = "Failed to connect to Phoenix backend";                                                                                                                                       
		});                                                                                                                                                                                       
																																																
	// Listen for real-time price updates                                                                                                                                                       
	channel.on("price_update", (data) => {                                                                                                                                                      
		const { symbol, price, timestamp, source } = data;                                                                                                                                        
		stocks = {                                                                                                                                                                                
		...stocks,                                                                                                                                                                              
		[symbol]: {                                                                                                                                                                             
			price,                                                                                                                                                                                
			timestamp,                                                                                                                                                                            
			source                                                                                                                                                                                
		}                                                                                                                                                                                       
		};                                                                                                                                                                                        
		console.log(`Updated ${symbol} with ${price} (source: ${source})`);                                                                                                                       
	});                                                                                                                                                                                         
																																																
	// Listen for initial stock data                                                                                                                                                            
	channel.on("init_stocks", ({stocks: initialStocks}) => {                                                                                                                                    
		stocks = initialStocks;                                                                                                                                                                   
		console.log("Received initial stocks:", stocks);                                                                                                                                          
	});                                                                                                                                                                                         
																																																
	return () => {                                                                                                                                                                              
		channel.leave();                                                                                                                                                                          
		socket.disconnect();                                                                                                                                                                      
	};                                                                                                                                                                                          
  });                                                                                                                                                                                                       
                                                                                                                                                                                              
  // Format price with 2 decimal places                                                                                                                                                       
  function formatPrice(price) {                                                                                                                                                               
    return price ? `$${price.toFixed(2)}` : 'N/A';                                                                                                                                            
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  // Format timestamp to readable time                                                                                                                                                        
  function formatTime(timestamp) {                                                                                                                                                            
    if (!timestamp) return 'N/A';                                                                                                                                                             
    return new Date(timestamp).toLocaleTimeString();                                                                                                                                          
  }      

  function getPriceClass(stock) {                                                                                                                                                             
    if (!stock) return '';                                                                                                                                                                    
    return stock.source === 'fallback' ? 'fallback-price' : 'real-time-price';                                                                                                                
  }                                                                                                                                                                                         
</script>                                                                                                                                                                                     
                                                                                                                                                                                              
<main>                                                                                                                                                                                        
  <h1>Stock Dashboard</h1>                                                                                                                                                                    
                                                                                                                                                                                              
  <div class="status-container">                                                                                                                                                              
    <div class="status-indicator {connected ? 'connected' : 'disconnected'}"></div>                                                                                                           
    <p>{message}</p>                                                                                                                                                                          
  </div>                                                                                                                                                                                      
                                                                                                                                                                                              
  <div class="stocks-container">                                                                                                                                                              
    <h2>Real-time Stock Prices</h2>                                                                                                                                                           
                                                                                                                                                                                              
    {#each Object.entries(stockCategories) as [category, symbols]}                                                                                                                            
      <div class="category">                                                                                                                                                                  
        <h3>{category}</h3>                                                                                                                                                                   
        <table>                                                                                                                                                                               
          <thead>                                                                                                                                                                             
            <tr>                                                                                                                                                                              
              <th>Symbol</th>                                                                                                                                                                 
              <th>Price</th>                                                                                                                                                                  
              <th>Last Update</th>                                                                                                                                                            
              <th>Source</th>                                                                                                                                                                 
            </tr>                                                                                                                                                                             
          </thead>                                                                                                                                                                            
          <tbody>                                                                                                                                                                             
            {#each symbols as symbol}                                                                                                                                                         
              <tr>                                                                                                                                                                            
                <td>{symbol}</td>                                                                                                                                                             
                <td class={getPriceClass(stocks[symbol])}>                                                                                                                                    
                  {#if stocks[symbol]}                                                                                                                                                        
                    {formatPrice(stocks[symbol].price)}                                                                                                                                       
                  {:else}                                                                                                                                                                     
                    Loading...                                                                                                                                                                
                  {/if}                                                                                                                                                                       
                </td>                                                                                                                                                                         
                <td>                                                                                                                                                                          
                  {#if stocks[symbol]}                                                                                                                                                        
                    {formatTime(stocks[symbol].timestamp)}                                                                                                                                    
                  {:else}                                                                                                                                                                     
                    -                                                                                                                                                                         
                  {/if}                                                                                                                                                                       
                </td>                                                                                                                                                                         
                <td>                                                                                                                                                                          
                  {#if stocks[symbol]}                                                                                                                                                        
                    {stocks[symbol].source === 'fallback' ? 'Fallback' : 'Real-time'}                                                                                                         
                  {:else}                                                                                                                                                                     
                    -                                                                                                                                                                         
                  {/if}                                                                                                                                                                       
                </td>                                                                                                                                                                         
              </tr>                                                                                                                                                                           
            {/each}                                                                                                                                                                           
          </tbody>                                                                                                                                                                            
        </table>                                                                                                                                                                              
      </div>                                                                                                                                                                                  
    {/each}                                                                                                                                                                                   
  </div>                                                                                                                                                                              
</main>                                                                                                                                                                                       
                                                                                                                                                                                              
<style>                                                                                                                                                                                       
  main {                                                                                                                                                                                      
    font-family: Arial, sans-serif;                                                                                                                                                           
    max-width: 1200px;                                                                                                                                                                        
    margin: 0 auto;                                                                                                                                                                           
    padding: 20px;                                                                                                                                                                            
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  h1 {                                                                                                                                                                                        
    color: #333;                                                                                                                                                                              
    text-align: center;                                                                                                                                                                       
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .status-container {                                                                                                                                                                         
    display: flex;                                                                                                                                                                            
    align-items: center;                                                                                                                                                                      
    margin: 20px 0;                                                                                                                                                                           
    padding: 10px;                                                                                                                                                                            
    background-color: #f5f5f5;                                                                                                                                                                
    border-radius: 5px;                                                                                                                                                                       
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .status-indicator {                                                                                                                                                                         
    width: 12px;                                                                                                                                                                              
    height: 12px;                                                                                                                                                                             
    border-radius: 50%;                                                                                                                                                                       
    margin-right: 10px;                                                                                                                                                                       
  }        

  .real-time-price {                                                                                                                                                                          
    color: #4CAF50;  /* Green for real-time data */                                                                                                                                           
    font-weight: bold;                                                                                                                                                                        
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .fallback-price {                                                                                                                                                                           
    color: #F44336;  /* Red for fallback data */                                                                                                                                              
    font-weight: bold;                                                                                                                                                                        
  }                                                                                                                                                                                                       
                                                                                                                                                                                              
  .connected {                                                                                                                                                                                
    background-color: #4CAF50;                                                                                                                                                                
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .disconnected {                                                                                                                                                                             
    background-color: #F44336;                                                                                                                                                                
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .stocks-container {                                                                                                                                                                         
    background-color: white;                                                                                                                                                                  
    border-radius: 5px;                                                                                                                                                                       
    padding: 20px;                                                                                                                                                                            
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);                                                                                                                                                 
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .stock-categories {                                                                                                                                                                         
    display: flex;                                                                                                                                                                            
    flex-wrap: wrap;                                                                                                                                                                          
    gap: 20px;                                                                                                                                                                                
    margin-top: 20px;                                                                                                                                                                         
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .category {                                                                                                                                                                                 
    flex: 1;                                                                                                                                                                                  
    min-width: 300px;                                                                                                                                                                         
    background-color: #f9f9f9;                                                                                                                                                                
    padding: 15px;                                                                                                                                                                            
    border-radius: 5px;                                                                                                                                                                       
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  h3 {                                                                                                                                                                                        
    margin-top: 0;                                                                                                                                                                            
    color: #555;                                                                                                                                                                              
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  table {                                                                                                                                                                                     
    width: 100%;                                                                                                                                                                              
    border-collapse: collapse;                                                                                                                                                                
    margin-top: 10px;                                                                                                                                                                         
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  th, td {                                                                                                                                                                                    
    padding: 8px;                                                                                                                                                                             
    text-align: left;                                                                                                                                                                         
    border-bottom: 1px solid #ddd;                                                                                                                                                            
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  th {                                                                                                                                                                                        
    background-color: #f2f2f2;                                                                                                                                                                
    font-weight: bold;                                                                                                                                                                        
  }                                                                                                                                                                                           
                                                                                                                                                                                              
  .price {                                                                                                                                                                                    
    font-weight: bold;                                                                                                                                                                        
  }                                                                                                                                                                                           
</style> 
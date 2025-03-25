# Web Search Feature for Onit

This feature adds web search capabilities to Onit, allowing users to search the web for relevant information that will be included in the context for the AI's response.

## How It Works

1. Click the magnifying glass icon next to the microphone button to enable web search.
2. When web search is enabled (the icon turns blue), your next query will trigger a web search.
3. The search results will be added to the context before the AI generates a response.
4. The sources of the information will be included in the context.

## Setup Instructions

### Starting the Perplexica Server

The web search feature requires the Perplexica server to be running. To start the server:

1. Open a terminal
2. Navigate to the Onit directory
3. Run the start script:
   ```
   ./start-perplexica.sh
   ```
4. Wait for the server to start (it will be available at http://localhost:3000)

### API Keys

Perplexica requires API keys for the search functionality. You'll need to set up:

1. OpenAI API key for the chat and embedding models
2. (Optional) Google Search API key for better search results

To configure these keys, visit the Perplexica web interface at http://localhost:3000 after starting the server.

## Technical Details

- The web search feature uses the Perplexica API to perform searches
- Search results are added as a context item with the app name "Web Search"
- The search includes both the query and conversation history for better context
- If a search fails, the query will still be sent to the AI without the search context
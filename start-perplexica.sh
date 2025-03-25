#!/bin/bash

# Change to the Perplexica directory
cd "$(dirname "$0")/Perplexica"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "npm is not installed. Please install Node.js and npm."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Start the development server
echo "Starting Perplexica server..."
npm run dev
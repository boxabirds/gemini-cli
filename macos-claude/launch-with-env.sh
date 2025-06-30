#!/bin/bash

# This script launches GeminiStudio with environment variables
# You can either:
# 1. Set GEMINI_API_KEY in your shell: export GEMINI_API_KEY="your-key-here"
# 2. Create a .env file in this directory with: GEMINI_API_KEY=your-key-here
# 3. Pass it directly: GEMINI_API_KEY="your-key" ./launch-with-env.sh

# Load .env file if it exists
if [ -f .env ]; then
    echo "Loading environment from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo "⚠️  Warning: GEMINI_API_KEY not found in environment"
    echo "   You can:"
    echo "   1. export GEMINI_API_KEY='your-key-here'"
    echo "   2. Create a .env file with GEMINI_API_KEY=your-key-here"
    echo "   3. Run: GEMINI_API_KEY='your-key' ./launch-with-env.sh"
    echo ""
    echo "   Continuing anyway - you can enter the key in the app..."
fi

# Build if needed
if [ ! -d "./build/Build/Products/Debug/GeminiStudio.app" ]; then
    echo "App not found. Building..."
    ./build.sh
    if [ $? -ne 0 ]; then
        echo "Build failed!"
        exit 1
    fi
fi

# Launch the app with environment variables
echo "Launching GeminiStudio..."
open ./build/Build/Products/Debug/GeminiStudio.app --env GEMINI_API_KEY="$GEMINI_API_KEY"
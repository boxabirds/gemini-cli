#!/bin/bash

# This script runs the app and shows logs in the terminal

echo "🚀 Building and launching GeminiStudio with logging..."

# Always build to get latest changes
echo "📦 Building app..."
./build.sh
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Check for GEMINI_API_KEY
if [ -z "$GEMINI_API_KEY" ]; then
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "⚠️  No GEMINI_API_KEY found. The app will prompt for it."
fi

echo "📋 Starting log stream..."
echo "Press Ctrl+C to stop"
echo "----------------------------------------"

# Launch the app in background
open ./build/Build/Products/Debug/GeminiStudio.app --env GEMINI_API_KEY="$GEMINI_API_KEY" &

# Stream logs
log stream --predicate 'subsystem == "com.gemini.studio"' --style compact
#!/bin/bash

# Clean build directory if requested
if [ "$1" == "clean" ]; then
    echo "Cleaning build directory..."
    rm -rf ./build
fi

# Build the project
echo "Building GeminiStudio..."
xcodebuild -project GeminiStudio.xcodeproj \
    -scheme GeminiStudio \
    -configuration Debug \
    -derivedDataPath ./build \
    build

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    echo "App location: ./build/Build/Products/Debug/GeminiStudio.app"
else
    echo "❌ Build failed!"
    exit 1
fi
#!/bin/bash

echo "Building GeminiStudio..."
xcodebuild -scheme GeminiStudio -configuration Debug -derivedDataPath ./build build

if [ $? -eq 0 ]; then
    echo "Build succeeded! Launching app..."
    open ./build/Build/Products/Debug/GeminiStudio.app
else
    echo "Build failed!"
    exit 1
fi
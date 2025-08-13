#!/usr/bin/env bash

# Script to debug file picker windows
# Run this, then open a file picker to see its properties

echo "Monitoring for new windows. Open a file picker now..."
echo "Press Ctrl+C to stop monitoring"

while true; do
    hyprctl clients -j | jq -r '.[] | select(.floating == true) | "Class: \(.class) | Title: \(.title) | Size: \(.size[0])x\(.size[1]) | Pos: \(.at[0]),\(.at[1])"' | grep -v "^$"
    sleep 1
done
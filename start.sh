#!/bin/sh
# Start the first process (whatsapp-bridge) in the foreground
whatsapp-bridge/whatsapp-bridge-main &
# Wait for 5 seconds
sleep 5

# Start the second process (uv) in the foreground
uv run main.py --host 0.0.0.0 --port 8000
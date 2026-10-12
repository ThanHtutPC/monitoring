#!/bin/bash

set -e

echo "🛑 Stopping containers..."
docker compose down

echo "🚀 Starting containers..."
docker compose up -d

echo "📋 Status:"
docker compose ps

echo "✅ Done!"

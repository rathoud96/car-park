#!/bin/bash
set -e

# Generate secret key base if not provided
if [ -z "$SECRET_KEY_BASE" ]; then
    echo "Generating SECRET_KEY_BASE..."
    export SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')
fi

echo "🚀 Starting Car Park application..."
echo "📊 Environment: $MIX_ENV"
echo "🌐 Host: $PHX_HOST"
echo "🔧 Database: $DB_HOST:$DB_PORT/$DB_NAME"

# Wait for database to be ready
echo "⏳ Waiting for database..."
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; then
        echo "✅ Database is ready!"
        break
    fi
    
    attempt=$((attempt + 1))
    echo "⏳ Database not ready (attempt $attempt/$max_attempts), waiting..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Database connection timeout. Exiting."
    exit 1
fi

# Run database migrations
echo "🔄 Running database migrations..."
bin/car_park eval "CarPark.Release.migrate"

# Start the application
echo "🎉 Starting Car Park application..."
exec bin/car_park start 
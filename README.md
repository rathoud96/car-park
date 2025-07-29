# CarPark

A Phoenix-based API service for finding nearest car parks with available parking slots. The application fetches real-time car park data from the Singapore government API and provides a RESTful interface for location-based car park queries.

## Features

- 🚗 Find nearest car parks with available parking slots
- 📍 Location-based search using latitude/longitude coordinates
- 📊 Real-time data from Singapore government car park API
- 🔄 Automatic data synchronization with external API
- 📄 Pagination support for large result sets
- 🐳 Docker support for easy deployment
- 🏥 Health check endpoint for monitoring

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Or Elixir 1.18+ and PostgreSQL 15+

### Running with Docker (Recommended)

```bash
# Build and start all services
docker compose up --build

# Or run in detached mode
docker compose up --build -d
```

#### Useful Docker Commands

```bash
# View logs
docker compose logs -f app

# Access database
docker compose exec db psql -U postgres -d car_park_prod

# Run migrations manually
docker compose exec app bin/car_park eval "CarPark.Release.migrate"

# Stop all services
docker compose down

# Stop and remove volumes
docker compose down -v
```

### Running Locally

#### Setup

```bash
# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Start the server
mix phx.server
```

#### Environment Variables

Create a `.env` file or set the following environment variables:

```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/car_park_dev
SECRET_KEY_BASE=your_secret_key_here
CAR_PARK_API_URL=https://api.data.gov.sg/v1/transport/carpark-availability
```

## API Documentation

### Base URL

- **Production**: `http://localhost:4000`
- **Development**: `http://localhost:4000`

### Endpoints

#### Health Check

Check if the service is running properly.

```http
GET /health
```

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2025-07-28T14:47:17.219232Z",
  "service": "car_park"
}
```

#### Find Nearest Car Parks

Find the nearest car parks to a given location with available parking slots.

```http
GET /carparks/nearest
```

**Query Parameters:**

| Parameter   | Type    | Required | Default | Description                           |
| ----------- | ------- | -------- | ------- | ------------------------------------- |
| `latitude`  | float   | Yes      | -       | Latitude coordinate                   |
| `longitude` | float   | Yes      | -       | Longitude coordinate                  |
| `page`      | integer | No       | 1       | Page number for pagination            |
| `per_page`  | integer | No       | 10      | Number of results per page (max: 100) |

**Example Request:**

```bash
curl "http://localhost:4000/carparks/nearest?latitude=1.3521&longitude=103.8198&page=1&per_page=5"
```

**Success Response (200):**

```json
{
  "data": [
    {
      "address": "BLK 1/3 TELOK BLANGAH CRESCENT",
      "latitude": 1.275,
      "longitude": 103.819,
      "total_lots": 100,
      "available_lots": 45
    },
    {
      "address": "BLK 2/4 TELOK BLANGAH CRESCENT",
      "latitude": 1.276,
      "longitude": 103.82,
      "total_lots": 80,
      "available_lots": 12
    }
  ],
  "pagination": {
    "total_count": 150,
    "page": 1,
    "per_page": 5,
    "total_pages": 30
  },
  "timestamp": "2025-07-28T14:47:17.219232Z"
}
```

**Error Response (400):**

```json
{
  "success": false,
  "error": "Invalid parameters: Missing or invalid float value",
  "timestamp": "2025-07-28T14:47:17.219232Z"
}
```

### Error Codes

| Status Code | Description                      |
| ----------- | -------------------------------- |
| 200         | Success                          |
| 400         | Bad Request - Invalid parameters |
| 500         | Internal Server Error            |

## Development

### Code Quality Tools

This project uses several tools to maintain high code quality:

#### Credo - Static Code Analysis

```bash
# Run code analysis
mix credo

# Run with strict settings
mix credo --strict

# Explain specific issues
mix credo explain
```

#### Dialyzer - Type Checking

```bash
# Run type checking
mix dialyzer

# Build PLT (first time only)
mix dialyzer --plt
```

#### TypedEctoSchema - Type-Safe Schemas

This project uses `typed_ecto_schema` for type-safe Ecto schemas. When creating new schemas, use the `typed_schema` macro:

```elixir
defmodule CarPark.Schemas.User do
  use TypedEctoSchema

  typed_schema "users" do
    field :email, :string
    field :name, :string
    timestamps()
  end
end
```

#### Code Quality Aliases

```bash
# Run all code quality checks
mix code.check

# Fix auto-fixable issues
mix code.fix
```

### Testing

```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/car_park_web/controllers/car_park_controller_test.exs
```

### Database

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback migrations
mix ecto.rollback

# Reset database
mix ecto.reset
```

## Architecture

### Components

- **CarParkController**: Handles HTTP requests for car park data
- **CarParkLocationService**: Business logic for finding nearest car parks
- **CarParkDataWorker**: Background worker for syncing external API data
- **CarParkAPI**: External API client for Singapore government data
- **CarParkData**: Ecto schema for storing car park information

### Data Flow

1. **Data Ingestion**: `CarParkDataWorker` periodically fetches data from Singapore government API
2. **Storage**: Car park data is stored in PostgreSQL database
3. **Query**: `CarParkLocationService` queries database for nearest car parks
4. **API Response**: `CarParkController` formats and returns JSON responses

## Tradeoffs

This application makes several key design decisions that balance performance, data freshness, and complexity:

### Memory Usage vs. Response Time

**In-memory location cache provides sub-100ms responses but requires 50-100MB RAM per instance**

### Data Freshness vs. Performance

**Startup-only data updates ensure consistent performance but data can be hours old**

### Database Performance vs. Query Complexity

**Missing composite index on (carpark_number, update_datetime DESC) for latest data queries**

**No pagination indexes for large result sets could cause performance degradation**

### Coordinate Accuracy vs. Dependency Simplicity

**Custom SVY21 to WGS84 conversion avoids external dependencies but may have accuracy limitations**

## Deployment

### Production Considerations

- Set appropriate environment variables for production
- Use proper SSL/TLS certificates
- Configure database connection pooling
- Set up monitoring and logging
- Consider using Docker Swarm or Kubernetes for orchestration

### Environment Variables

| Variable           | Description                  | Default           |
| ------------------ | ---------------------------- | ----------------- |
| `DATABASE_URL`     | PostgreSQL connection string | -                 |
| `SECRET_KEY_BASE`  | Phoenix secret key base      | -                 |
| `CAR_PARK_API_URL` | External car park API URL    | Singapore gov API |
| `MIX_ENV`          | Environment (prod/dev)       | dev               |

## Troubleshooting

### Common Issues

#### Database Connection Issues

```bash
# Check if PostgreSQL is running
docker compose ps

# View PostgreSQL logs
docker compose logs db

# Ensure database URL is correct in environment variables
```

#### Port Conflicts

If ports 4000 or 5432 are already in use:

```bash
# Stop existing services
docker compose down

# Or modify port mappings in docker-compose.yml
```

#### Build Issues

```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker compose build --no-cache
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Run code quality checks
7. Submit a pull request

## License

This project is licensed under the MIT License.

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

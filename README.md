# The-Habit-Tracker

A Flask-based habit tracking application with PostgreSQL database, using Gunicorn WSGI server for production deployment.

## Features

- Create, read, update, and delete habits
- Track habit completion with dates
- Clean, responsive UI with Bootstrap
- PostgreSQL database backend
- Docker containerization
- Production-ready with Gunicorn WSGI server

## Project Structure

```
The-Habit-Tracker/
├── habit-tracker/          # Application source code
│   ├── app/               # Flask application
│   │   ├── __init__.py    # Flask app factory
│   │   ├── config.py      # Configuration classes (dev/prod/test)
│   │   ├── routes/        # Route blueprints
│   │   │   ├── __init__.py
│   │   │   └── habit_routes.py
│   │   ├── models/        # Database models
│   │   │   ├── __init__.py
│   │   │   └── habit.py
│   │   ├── forms/         # WTForms definitions
│   │   │   ├── __init__.py
│   │   │   └── habit_form.py
│   │   ├── templates/     # HTML templates
│   │   └── static/        # Static files (CSS, JS, images)
│   ├── run.py            # Application entry point (dev & prod)
│   ├── init_db.py        # Database initialization
│   ├── tests/            # Test suite
│   ├── requirements.txt  # Python dependencies
│   ├── pytest.ini       # Pytest configuration
│   └── run_tests.py     # Test runner script
├── terraform/            # Infrastructure as Code
├── Dockerfile           # Multi-stage Docker build
├── docker-compose.yml   # Development environment
├── docker-compose.prod.yml # Production environment
└── README.md            # This file
```

## Prerequisites

- Docker and Docker Compose
- Python 3.11+ (for local development)

## Quick Start with Docker

### Development Environment

1. Clone the repository:

```bash
git clone <repository-url>
cd The-Habit-Tracker
```

2. Start the development environment:

```bash
docker-compose up --build
```

3. Access the application at `http://localhost:5000`

### Production Environment

1. Set your production secret key:

```bash
export SECRET_KEY="your-secure-production-secret-key"
```

2. Start the production environment:

```bash
docker-compose -f docker-compose.prod.yml up --build
```

## WSGI Server Configuration

This application uses a unified approach with `run.py` for both development and production:

- **Development**: Uses Flask's built-in development server with `flask run --host=0.0.0.0 --port=5000 --debug`
- **Production**: Uses **Gunicorn** WSGI server for better performance and production readiness

### Development vs Production

- **Development**: Flask development server with auto-reload and debug mode
- **Production**: Gunicorn with 4 workers and optimized settings

## Environment Variables

The application uses the following environment variables:

- `SECRET_KEY`: Flask secret key for session management
- `DB_HOST`: PostgreSQL host (default: postgres)
- `DB_PORT`: PostgreSQL port (default: 5432)
- `DB_NAME`: Database name (default: habit_tracker)
- `DB_USER`: Database user (default: habit_user)
- `DB_PASSWORD`: Database password (default: habit_password)

## Local Development

1. Copy the environment template:

```bash
cp env.example .env
```

2. Install dependencies:

```bash
cd habit-tracker
pip install -r requirements.txt
```

3. Set up PostgreSQL database and update `.env` with your credentials

4. Run the application:

```bash
# Development server
cd habit-tracker
python run.py

# Or with Flask CLI (recommended)
cd habit-tracker
flask run --host=0.0.0.0 --port=5000 --debug
```

## Database

The application uses PostgreSQL as the database backend. The database is automatically created when the containers start up.

## Testing

Run tests with Docker:

```bash
docker-compose exec habit-tracker bash -c "cd habit-tracker && python -m pytest"
```

Or locally:

```bash
cd habit-tracker
python -m pytest
```

## Docker Services

- **habit-tracker**: Flask application with Gunicorn WSGI server
- **postgres**: PostgreSQL database
- **pg-admin**: PostgreSQL administration interface (development only)

## Production Deployment

For production deployment, use the production Docker Compose override:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

This configuration:

- Uses PostgreSQL with production optimizations
- Includes resource limits and memory management
- Optimized database settings for performance
- Includes backup volume for PostgreSQL

## Infrastructure as Code

The project includes comprehensive Terraform configurations for Azure deployment:

```bash
cd terraform
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

See the [terraform/README.md](terraform/README.md) for detailed infrastructure documentation.

## License

MIT

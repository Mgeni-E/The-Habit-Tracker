# Habit Tracker Application

This directory contains the core Flask application for the Habit Tracker project.

## Structure

```
habit-tracker/
├── app/               # Flask application package
│   ├── __init__.py    # Flask app factory
│   ├── config.py      # Configuration classes (dev/prod/test)
│   ├── routes/        # Route blueprints
│   │   ├── __init__.py
│   │   └── habit_routes.py
│   ├── models/        # Database models
│   │   ├── __init__.py
│   │   └── habit.py
│   ├── forms/         # WTForms definitions
│   │   ├── __init__.py
│   │   └── habit_form.py
│   ├── templates/     # HTML templates (Jinja2)
│   └── static/        # Static files (CSS, JS, images)
├── run.py            # Application entry point (dev & prod)
├── init_db.py        # Database initialization script
├── tests/            # Test suite
│   ├── conftest.py   # Pytest configuration and fixtures
│   ├── test_models.py # Model tests
│   ├── test_forms.py  # Form validation tests
│   └── test_routes.py # Route and view tests
├── requirements.txt  # Python dependencies
├── pytest.ini       # Pytest configuration
└── run_tests.py     # Test runner script
```

## Development

### Local Development

1. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

2. Run the development server:

   ```bash
   # Using Python directly
   python run.py

   # Or using Flask CLI (recommended)
   flask run --host=0.0.0.0 --port=5000 --debug
   ```

3. Run tests:
   ```bash
   python -m pytest
   ```

### Docker Development

The application is designed to run in Docker containers. See the root directory for Docker configuration files.

## Application Features

- **Habit Management**: Create, read, update, and delete habits
- **Completion Tracking**: Track habit completion with dates
- **Database Integration**: PostgreSQL with SQLAlchemy ORM
- **Form Validation**: WTForms for input validation
- **Responsive UI**: Bootstrap-based templates

## Testing

The test suite includes:

- Unit tests for models
- Form validation tests
- Route and view tests
- Database integration tests

Run tests with:

```bash
python -m pytest
```

## Database

The application uses PostgreSQL with the following models:

- **Habit**: Core habit information
- **Completion**: Daily habit completion tracking

Database initialization is handled by `app/init_db.py`.

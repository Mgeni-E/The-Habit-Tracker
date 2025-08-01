import pytest
from datetime import date, timedelta
from app import create_app, db
from app.models import Habit, Completion


@pytest.fixture
def app():
    """Create and configure a new app instance for each test."""
    test_config = {
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        "WTF_CSRF_ENABLED": False,
        "SECRET_KEY": "test-secret-key",
    }
    app = create_app(test_config=test_config)
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()


@pytest.fixture
def sample_habit(app):
    """Create a sample habit for testing."""
    with app.app_context():
        habit = Habit(
            name="Test Habit",
            frequency="daily",
            start_date=date.today() - timedelta(days=7),
        )
        db.session.add(habit)
        db.session.commit()
        return habit


@pytest.fixture
def sample_habits(app):
    """Create multiple sample habits for testing."""
    with app.app_context():
        habits = []
        habit_data = [
            ("Exercise", "daily"),
            ("Read", "daily"),
            ("Meditate", "weekly"),
        ]

        for name, frequency in habit_data:
            habit = Habit(
                name=name,
                frequency=frequency,
                start_date=date.today() - timedelta(days=5),
            )
            db.session.add(habit)
            habits.append(habit)

        db.session.commit()
        return habits


@pytest.fixture
def sample_completions(app, sample_habit):
    """Create sample completions for testing."""
    with app.app_context():
        completions = []
        dates = [
            date.today(),
            date.today() - timedelta(days=1),
            date.today() - timedelta(days=2),
        ]

        for d in dates:
            completion = Completion(habit_id=sample_habit.id, date_completed=d)
            db.session.add(completion)
            completions.append(completion)

        db.session.commit()
        return completions
